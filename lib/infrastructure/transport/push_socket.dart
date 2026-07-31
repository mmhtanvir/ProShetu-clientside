import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/app_config.dart';
import '../crypto/device_keys.dart';
import 'api_client.dart';

/// A wake-up hint pushed over `/ws/push` — never plaintext content,
/// just enough to know something is worth pulling over REST
/// (README: "Only hints cross the socket — never plaintext;
/// ciphertext is still fetched over REST").
class PushHint {
  const PushHint({required this.type, required this.raw});

  final String type; // e.g. "event", "call_signal"
  final Map<String, dynamic> raw;
}

/// Holds one authenticated socket to `/ws/push` so the server can
/// nudge this device the instant something arrives, instead of
/// relying on polling. Auth reuses the same signature-challenge
/// scheme as REST, passed as query params
/// (`identity`/`nonce`/`signature`) since a WebSocket handshake can't
/// carry the custom headers `SigningInterceptor` uses.
///
/// This is transport plumbing only — receiving a hint still means
/// fetching and decrypting the real content over REST, and
/// decryption is the unimplemented E2E seam
/// (infrastructure/crypto/e2e_placeholder.dart).
class PushSocket {
  PushSocket(this._api);

  final ApiClient _api;
  WebSocketChannel? _channel;
  StreamController<PushHint>? _hints;

  Stream<PushHint> get hints => (_hints ??= StreamController<PushHint>.broadcast()).stream;

  Future<void> connect() async {
    if (AppConfig.wsBaseUrl.isEmpty) {
      throw StateError('WS_BASE_URL not configured (see AppConfig)');
    }
    if (!DeviceKeys.isUnlocked) {
      throw StateError('Cannot open push socket before identity is unlocked');
    }
    final String pub = await DeviceKeys.ed25519PublicHex();

    // Reuse the same challenge/sign dance the REST signing
    // interceptor does, just inlined here since a WS handshake has
    // no request body/header interception point.
    final challenge = await _api.getJson('/v1/challenge', query: {'pub': pub});
    final String nonce = challenge.fold(
      (f) => throw StateError(f.message),
      (json) => json['nonce'] as String,
    );
    final String signature = await DeviceKeys.signNonceHex(nonce);

    final Uri uri = Uri.parse('${AppConfig.wsBaseUrl}/ws/push').replace(
      queryParameters: {
        'identity': pub,
        'nonce': nonce,
        'signature': signature,
      },
    );

    _channel = WebSocketChannel.connect(uri);
    // Without this, a failed handshake only surfaces via the stream's
    // onError (below), which is intentionally a no-op — callers would
    // see connect() succeed even when the socket never actually
    // connected.
    await _channel!.ready;
    _channel!.stream.listen(
      (dynamic raw) {
        try {
          final Map<String, dynamic> json =
              jsonDecode(raw as String) as Map<String, dynamic>;
          (_hints ??= StreamController<PushHint>.broadcast()).add(
            PushHint(type: json['type'] as String? ?? 'unknown', raw: json),
          );
        } catch (_) {
          // Malformed hint — ignore rather than crash the socket.
        }
      },
      onError: (_) {}, // caller observes via `hints`/reconnect logic later
      cancelOnError: false,
    );
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
