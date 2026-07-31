import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/crypto/e2e_placeholder.dart';
import '../../domain/call_session.dart';
import '../../domain/calling_repository.dart';
import '../providers/voice_providers.dart';

/// Drives one call at a time. Real signaling (POST /v1/call/signal,
/// GET /v1/call/poll) — but every signal's content still needs the
/// unimplemented E2E seam (infrastructure/crypto/e2e_placeholder.dart)
/// to actually encrypt, so a real call attempt will fail there today.
/// That's surfaced honestly via [CallSession.statusMessage] rather
/// than silently retried or hidden — the design spec's "truth over
/// comfort" principle for connection state applies to calls too.
///
/// NOTE: this drives signaling only. No audio ever flows — there is
/// no WebRTC (or other media) engine wired in this pass. See this
/// feature's README note in the delivery summary.
class CallController extends Notifier<CallSession?> {
  Timer? _pollTimer;
  int _seq = 0;

  @override
  CallSession? build() {
    ref.onDispose(() => _pollTimer?.cancel());
    return null;
  }

  String _newCallId() {
    final Random r = Random.secure();
    final int a = r.nextInt(1 << 32);
    final int b = DateTime.now().microsecondsSinceEpoch;
    return '$a-$b';
  }

  Future<void> startOutgoingCall({
    required String peerMailboxId,
    required String peerName,
  }) async {
    final String callId = _newCallId();
    state = CallSession(
      callId: callId,
      peerMailboxId: peerMailboxId,
      peerName: peerName,
      phase: CallPhase.dialing,
      outgoing: true,
      statusMessage: 'Calling…',
    );
    await _sendSignal(CallSignalKind.offer);
    _startPolling();
  }

  /// Answering or declining needs to know who to send the reply
  /// signal TO — but [CallSignalOutSerializer] (backend) has no
  /// sender field at all, by design: signals are sealed-sender, same
  /// as sync events. The caller's mailbox_id only exists inside the
  /// ciphertext, recoverable by decrypting it — the same
  /// unimplemented E2E seam as everything else. So both paths below
  /// fail at that same point today, honestly, rather than guessing a
  /// recipient.
  Future<void> acceptIncoming(CallSignal offer, {required String peerName}) async {
    state = CallSession(
      callId: offer.callId,
      peerMailboxId: '',
      peerName: peerName,
      phase: CallPhase.connecting,
      outgoing: false,
      statusMessage: 'Connecting…',
    );
    try {
      // Recovers the caller's mailbox_id (needed to address the
      // answer signal) from inside the sealed ciphertext. Always
      // throws today — see this method's doc comment above.
      await E2ePlaceholder.decryptFromSender(offer.ciphertext);
    } on UnimplementedError catch (e) {
      state = state?.copyWith(
        phase: CallPhase.failed,
        statusMessage:
            "Can't accept — the caller's identity is sealed inside the "
            'signal and end-to-end decryption is not implemented yet. '
            '(${e.message})',
      );
    }
  }

  Future<void> declineIncoming(CallSignal offer) async {
    // Same sealed-sender limitation as acceptIncoming: there is no
    // recipient to reply to without decrypting the offer first. A
    // decline the caller never receives is silently useless, so this
    // is a deliberate no-op today rather than sending to a bogus
    // recipient — the caller's own poll loop will simply time the
    // call out.
  }

  Future<void> hangUp() async {
    await _sendSignal(CallSignalKind.hangup);
    _pollTimer?.cancel();
    state = state?.copyWith(phase: CallPhase.ended, statusMessage: 'Call ended');
  }

  Future<void> _sendSignal(CallSignalKind kind) async {
    final CallSession? current = state;
    if (current == null) return;
    final CallingRepository repo = ref.read(callingRepositoryProvider);
    try {
      final List<int> ciphertext = await E2ePlaceholder.encryptForRecipient(
        recipientMailboxId: current.peerMailboxId,
        plaintext: const [], // signal has no content beyond `kind` itself
      );
      await repo.sendSignal(
        callId: current.callId,
        recipientMailboxId: current.peerMailboxId,
        kind: kind,
        seq: _seq++,
        ciphertext: ciphertext,
      );
    } on UnimplementedError catch (e) {
      state = current.copyWith(
        phase: CallPhase.failed,
        statusMessage:
            "Can't start a secure call yet — end-to-end call encryption "
            'is not implemented. (${e.message})',
      );
    } catch (e) {
      state = current.copyWith(
        phase: CallPhase.failed,
        statusMessage: 'Call signal failed: $e',
      );
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final CallSession? current = state;
      if (current == null ||
          current.phase == CallPhase.ended ||
          current.phase == CallPhase.failed) {
        _pollTimer?.cancel();
        return;
      }
      try {
        final CallingRepository repo = ref.read(callingRepositoryProvider);
        final List<CallSignal> signals = await repo.pollSignals();
        for (final CallSignal s in signals.where((s) => s.callId == current.callId)) {
          switch (s.kind) {
            case CallSignalKind.answer:
              state = current.copyWith(
                phase: CallPhase.active,
                statusMessage:
                    'Connected (signaling only — no audio in this build)',
              );
            case CallSignalKind.hangup:
            case CallSignalKind.busy:
              state = current.copyWith(
                phase: CallPhase.ended,
                statusMessage:
                    s.kind == CallSignalKind.busy ? 'Busy' : 'Call ended',
              );
              _pollTimer?.cancel();
            case CallSignalKind.offer:
            case CallSignalKind.candidate:
            case CallSignalKind.ringing:
              break;
          }
        }
      } catch (_) {
        // Transient poll failure — next tick retries. Don't flip the
        // UI to an error state for one missed poll.
      }
    });
  }

  void clear() {
    _pollTimer?.cancel();
    state = null;
  }
}

final callControllerProvider =
    NotifierProvider<CallController, CallSession?>(CallController.new);
