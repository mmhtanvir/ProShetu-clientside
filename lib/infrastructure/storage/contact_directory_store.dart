import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A locally-known contact: a display name + mailbox_id, plus (once
/// paired via the updated QR payload) their long-term X25519/Ed25519
/// identity public keys — pinned at pairing time (TOFU: the physical
/// act of scanning their QR code in person is the trust-establishment
/// event, same as `mailbox_id` already was). Without these two keys
/// pinned, there is no way to resolve who sent an E2E-encrypted
/// INITIAL message (sealed sender means no mailbox_id travels in the
/// envelope — only the sender's identity public keys do) or to
/// cross-check a session's provenance. Contacts paired before this
/// field existed will have both null — see ScanQrScreen for the
/// "re-pair to enable secure messaging" affordance that covers them.
class DirectoryContact extends Equatable {
  const DirectoryContact({
    required this.displayName,
    required this.mailboxId,
    this.ed25519Pub,
    this.x25519Pub,
  });

  final String displayName;
  final String mailboxId;
  final String? ed25519Pub;
  final String? x25519Pub;

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'mailboxId': mailboxId,
        if (ed25519Pub != null) 'ed25519Pub': ed25519Pub,
        if (x25519Pub != null) 'x25519Pub': x25519Pub,
      };

  static DirectoryContact fromJson(Map<String, dynamic> json) =>
      DirectoryContact(
        displayName: json['displayName'] as String,
        mailboxId: json['mailboxId'] as String,
        ed25519Pub: json['ed25519Pub'] as String?,
        x25519Pub: json['x25519Pub'] as String?,
      );

  @override
  List<Object?> get props =>
      [displayName, mailboxId, ed25519Pub, x25519Pub];
}

/// Real, complete storage for [DirectoryContact]s, populated by QR
/// pairing (my_qr_screen.dart / scan_qr_screen.dart) and by Add-by-
/// number. Everything downstream (SyncRepository, ChatRepository,
/// E2eCryptoService) consumes mailbox-addressed, key-pinned contacts
/// straight from here.
class ContactDirectoryStore {
  ContactDirectoryStore(this._storage);

  final FlutterSecureStorage _storage;
  static const String _key = 'directory_contacts_v1';

  Future<List<DirectoryContact>> all() async {
    final String? raw = await _storage.read(key: _key);
    if (raw == null) return const [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(DirectoryContact.fromJson)
        .toList();
  }

  Future<void> add(DirectoryContact contact) async {
    final List<DirectoryContact> current = await all();
    final List<DirectoryContact> next = [
      ...current.where((DirectoryContact c) => c.mailboxId != contact.mailboxId),
      contact,
    ];
    await _storage.write(
      key: _key,
      value: jsonEncode(next.map((DirectoryContact c) => c.toJson()).toList()),
    );
  }

  Future<void> remove(String mailboxId) async {
    final List<DirectoryContact> current = await all();
    await _storage.write(
      key: _key,
      value: jsonEncode(current
          .where((DirectoryContact c) => c.mailboxId != mailboxId)
          .map((DirectoryContact c) => c.toJson())
          .toList()),
    );
  }

  Future<DirectoryContact?> byMailboxId(String mailboxId) async {
    final List<DirectoryContact> current = await all();
    for (final DirectoryContact c in current) {
      if (c.mailboxId == mailboxId) return c;
    }
    return null;
  }

  /// Case-insensitive lookup by display name — used to resolve a
  /// chat/call target's mailbox_id from the name shown in the UI.
  Future<DirectoryContact?> byDisplayName(String name) async {
    final List<DirectoryContact> current = await all();
    for (final DirectoryContact c in current) {
      if (c.displayName.toLowerCase() == name.toLowerCase()) return c;
    }
    return null;
  }

  /// Resolves the sender of a decrypted INITIAL message: sealed
  /// sender means the envelope carries the sender's X25519 identity
  /// public key, never their mailbox_id, so this is the only way to
  /// find out who actually sent it.
  Future<DirectoryContact?> byX25519Pub(String x25519Pub) async {
    final List<DirectoryContact> current = await all();
    for (final DirectoryContact c in current) {
      if (c.x25519Pub == x25519Pub) return c;
    }
    return null;
  }
}
