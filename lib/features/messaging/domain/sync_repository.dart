import 'package:equatable/equatable.dart';

/// One event this device is offering to the fabric (already
/// encrypted — see infrastructure/crypto/e2e_placeholder.dart for why
/// producing that ciphertext isn't implemented yet).
class OutgoingEvent extends Equatable {
  const OutgoingEvent({
    required this.eventId,
    required this.recipientMailboxId,
    required this.priority,
    required this.ttlSeconds,
    required this.ciphertext,
  });

  final String eventId; // BLAKE2b-128(ciphertext), hex
  final String recipientMailboxId;
  final int priority; // 0..3
  final int ttlSeconds;
  final List<int> ciphertext;

  @override
  List<Object?> get props => [eventId, recipientMailboxId, priority, ttlSeconds];
}

class DeliveredEvent extends Equatable {
  const DeliveredEvent({
    required this.eventId,
    required this.priority,
    required this.ciphertext,
    required this.ttlExpiresAt,
  });

  final String eventId;
  final int priority;
  final List<int> ciphertext;
  final DateTime ttlExpiresAt;

  @override
  List<Object?> get props => [eventId, priority, ttlExpiresAt];
}

class SyncResult extends Equatable {
  const SyncResult({
    required this.accepted,
    required this.delivered,
    required this.wanted,
  });

  final List<String> accepted;
  final List<DeliveredEvent> delivered;
  final List<String> wanted;

  @override
  List<Object?> get props => [accepted, delivered, wanted];
}

/// Contract for apps/sync's `/v1/sync` reconciliation and `/v1/ack`.
/// This is the SAME reconciliation protocol the mesh transports run
/// (README: "one sync engine, three transports") — this repository
/// is only the backend-over-HTTP leg of it.
abstract interface class SyncRepository {
  Future<SyncResult> sync({
    List<OutgoingEvent> carrying = const [],
    List<String> knownEventIds = const [],
  });

  Future<void> ack(List<String> eventIds);
}
