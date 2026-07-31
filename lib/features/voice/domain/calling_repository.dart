import 'package:equatable/equatable.dart';

enum CallSignalKind { offer, answer, candidate, ringing, hangup, busy }

class CallSignal extends Equatable {
  const CallSignal({
    required this.callId,
    required this.kind,
    required this.seq,
    required this.ciphertext,
    required this.createdAt,
    required this.expiresAt,
  });

  final String callId;
  final CallSignalKind kind;
  final int seq;
  final List<int> ciphertext;
  final DateTime createdAt;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [callId, kind, seq, createdAt];
}

/// Contract for apps/calling: relaying small, sealed signalling
/// blobs (ring/offer/answer/hangup/candidate) between two
/// both-online peers not on the same local mesh. No voice media and
/// no WebRTC ever touch the backend (README) — media stays
/// peer-to-peer over the mesh.
abstract interface class CallingRepository {
  /// POST /v1/call/signal
  Future<void> sendSignal({
    required String callId,
    required String recipientMailboxId,
    required CallSignalKind kind,
    required int seq,
    required List<int> ciphertext,
    int ttlSeconds = 90,
  });

  /// GET /v1/call/poll — WebSocket push fallback.
  Future<List<CallSignal>> pollSignals();
}
