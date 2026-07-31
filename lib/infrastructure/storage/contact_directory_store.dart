import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A locally-known contact: a display name paired with the mailbox_id
/// their device registered under (apps/directory). This is the piece
/// `/v1/sync`'s `recipient_mailbox` needs that nothing in this app
/// currently collects.
class DirectoryContact extends Equatable {
  const DirectoryContact({required this.displayName, required this.mailboxId});

  final String displayName;
  final String mailboxId;

  Map<String, dynamic> toJson() =>
      {'displayName': displayName, 'mailboxId': mailboxId};

  static DirectoryContact fromJson(Map<String, dynamic> json) =>
      DirectoryContact(
        displayName: json['displayName'] as String,
        mailboxId: json['mailboxId'] as String,
      );

  @override
  List<Object?> get props => [displayName, mailboxId];
}

/// Real, complete storage for [DirectoryContact]s. Nothing populates
/// it yet: learning a contact's mailbox_id needs an out-of-band
/// exchange (e.g. scan their QR code, which encodes their
/// mailbox_id) that this app doesn't have a screen for today — see
/// this class's use sites for the "add a real contact" gap. Once
/// such a flow exists, call [add] with what it captures; everything
/// downstream (SyncRepository, ChatRepository) is ready to consume
/// mailbox-addressed contacts as soon as they exist here.
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
}
