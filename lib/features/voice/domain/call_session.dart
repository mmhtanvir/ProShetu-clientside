import 'package:equatable/equatable.dart';

enum CallPhase { dialing, ringingIncoming, connecting, active, ended, failed }

class CallSession extends Equatable {
  const CallSession({
    required this.callId,
    required this.peerMailboxId,
    required this.peerName,
    required this.phase,
    required this.outgoing,
    this.statusMessage,
  });

  final String callId;
  final String peerMailboxId;
  final String peerName;
  final CallPhase phase;
  final bool outgoing;

  /// Honest, plain-language status line — this app's design principle
  /// is "truth over comfort" for connection state (see the UI/UX
  /// spec's §0 design principles), so this is never a generic
  /// "Connecting..." spinner with no information.
  final String? statusMessage;

  CallSession copyWith({CallPhase? phase, String? statusMessage}) =>
      CallSession(
        callId: callId,
        peerMailboxId: peerMailboxId,
        peerName: peerName,
        phase: phase ?? this.phase,
        outgoing: outgoing,
        statusMessage: statusMessage ?? this.statusMessage,
      );

  @override
  List<Object?> get props => [callId, peerMailboxId, phase, statusMessage];
}
