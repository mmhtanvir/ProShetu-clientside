import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:sqflite/sqflite.dart';

import '../crypto/device_keys.dart';

enum MessageDirection { incoming, outgoing }

enum DeliveryState { pending, sent, failed }

/// One stored message. [content] is an opaque JSON-encodable map —
/// this storage layer doesn't know or care about ChatMessage's exact
/// shape (text/audioPath/replyToPreview/etc.); that mapping is the
/// caller's (ChatRepositoryImpl's) job, keeping this infra file free
/// of a features/ dependency.
class StoredMessage {
  const StoredMessage({
    required this.localId,
    required this.chatId,
    required this.direction,
    required this.timestamp,
    required this.deliveryState,
    required this.content,
    this.eventId,
  });

  final String localId;
  final String chatId;
  final String? eventId;
  final MessageDirection direction;
  final DateTime timestamp;
  final DeliveryState deliveryState;
  final Map<String, dynamic> content;
}

/// Real, persistent message-history storage — sqflite-backed since
/// this is append-heavy and queried by chat+time (the secure-storage
/// "read whole blob, rewrite whole blob" pattern used elsewhere,
/// ContactDirectoryStore/SessionStore, doesn't scale past a few
/// hundred messages).
///
/// Message CONTENT is AEAD-encrypted at rest via
/// DeviceKeys.deriveDomainKey('messages_v1') — independent of the E2E
/// transport encryption, real defense-in-depth if the device itself
/// is seized. Routing/sort metadata (chat_id, timestamp, direction,
/// delivery_state, event_id) stays unencrypted: the device itself is
/// already the user's trust boundary, same assumption
/// flutter_secure_storage/DeviceKeys already make elsewhere.
class MessageStore {
  static Database? _db;
  static const int _nonceLength = 12;
  static const int _macLength = 16;
  static final Chacha20 _aead = Chacha20.poly1305Aead();

  Future<Database> _database() async {
    final Database? existing = _db;
    if (existing != null) return existing;
    final String dir = await getDatabasesPath();
    final Database db = await openDatabase(
      '$dir/messages_v1.db',
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE messages (
            local_id TEXT PRIMARY KEY,
            chat_id TEXT NOT NULL,
            event_id TEXT UNIQUE,
            direction TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            delivery_state TEXT NOT NULL,
            content_encrypted BLOB NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_chat_time ON messages(chat_id, timestamp)',
        );
      },
    );
    _db = db;
    return db;
  }

  /// Inserts a message. Silently a no-op if [StoredMessage.eventId]
  /// already exists (the UNIQUE constraint) — this is the dedup
  /// guard against redelivery before an ack lands, with no separate
  /// bookkeeping needed.
  Future<void> insert(StoredMessage message) async {
    final Database db = await _database();
    final List<int> encrypted = await _encryptContent(message.content);
    await db.insert(
      'messages',
      <String, Object?>{
        'local_id': message.localId,
        'chat_id': message.chatId,
        'event_id': message.eventId,
        'direction': message.direction.name,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'delivery_state': message.deliveryState.name,
        'content_encrypted': encrypted,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<StoredMessage>> messagesFor(String chatId) async {
    final Database db = await _database();
    final List<Map<String, Object?>> rows = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: <Object?>[chatId],
      orderBy: 'timestamp ASC',
    );
    final List<StoredMessage> out = [];
    for (final Map<String, Object?> row in rows) {
      out.add(await _rowToMessage(row));
    }
    return out;
  }

  Future<void> markSent(String localId, String eventId) async {
    final Database db = await _database();
    await db.update(
      'messages',
      <String, Object?>{
        'delivery_state': DeliveryState.sent.name,
        'event_id': eventId,
      },
      where: 'local_id = ?',
      whereArgs: <Object?>[localId],
    );
  }

  Future<void> markFailed(String localId) async {
    final Database db = await _database();
    await db.update(
      'messages',
      <String, Object?>{'delivery_state': DeliveryState.failed.name},
      where: 'local_id = ?',
      whereArgs: <Object?>[localId],
    );
  }

  /// Outbound messages still awaiting a successful sync() — retried
  /// by MessageSyncCoordinator on the next sync attempt rather than
  /// lost, unlike the old in-memory-only ChatRepositoryImpl.
  Future<List<StoredMessage>> pendingOutgoing() async {
    final Database db = await _database();
    final List<Map<String, Object?>> rows = await db.query(
      'messages',
      where: 'delivery_state = ? AND direction = ?',
      whereArgs: <Object?>[
        DeliveryState.pending.name,
        MessageDirection.outgoing.name,
      ],
    );
    final List<StoredMessage> out = [];
    for (final Map<String, Object?> row in rows) {
      out.add(await _rowToMessage(row));
    }
    return out;
  }

  /// Wipes every stored message. Used only by account recovery
  /// (auth_repository_impl.dart) — after that flow mints a fresh
  /// device keypair, rows encrypted under the old key are permanently
  /// undecryptable, so there's nothing left to keep them for.
  Future<void> clearAll() async {
    final Database db = await _database();
    await db.delete('messages');
  }

  Future<bool> hasEvent(String eventId) async {
    final Database db = await _database();
    final List<Map<String, Object?>> rows = await db.query(
      'messages',
      where: 'event_id = ?',
      whereArgs: <Object?>[eventId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<StoredMessage> _rowToMessage(Map<String, Object?> row) async {
    final Map<String, dynamic> content =
        await _decryptContent(row['content_encrypted'] as List<int>);
    return StoredMessage(
      localId: row['local_id'] as String,
      chatId: row['chat_id'] as String,
      eventId: row['event_id'] as String?,
      direction: MessageDirection.values.byName(row['direction'] as String),
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      deliveryState:
          DeliveryState.values.byName(row['delivery_state'] as String),
      content: content,
    );
  }

  Future<List<int>> _encryptContent(Map<String, dynamic> content) async {
    final SecretKey key = await DeviceKeys.deriveDomainKey('messages_v1');
    final List<int> plain = utf8.encode(jsonEncode(content));
    final SecretBox box = await _aead.encrypt(plain, secretKey: key);
    return box.concatenation();
  }

  Future<Map<String, dynamic>> _decryptContent(List<int> encrypted) async {
    final SecretKey key = await DeviceKeys.deriveDomainKey('messages_v1');
    final SecretBox box = SecretBox.fromConcatenation(
      encrypted,
      nonceLength: _nonceLength,
      macLength: _macLength,
    );
    final List<int> plain = await _aead.decrypt(box, secretKey: key);
    return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
  }
}
