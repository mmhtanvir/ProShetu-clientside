import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../providers/onboarding_providers.dart';

class RecoveryVerifyState extends Equatable {
  const RecoveryVerifyState({
    required this.secondsLeft,
    this.verifying = false,
    this.errorMessage,
  });

  final int secondsLeft;
  final bool verifying;
  final String? errorMessage;

  bool get expired => secondsLeft <= 0;

  String get timeLabel {
    final int m = secondsLeft ~/ 60;
    final int s = secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  RecoveryVerifyState copyWith({
    int? secondsLeft,
    bool? verifying,
    String? errorMessage,
    bool clearError = false,
  }) =>
      RecoveryVerifyState(
        secondsLeft: secondsLeft ?? this.secondsLeft,
        verifying: verifying ?? this.verifying,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [secondsLeft, verifying, errorMessage];
}

/// Recovery-flow OTP verification. A near-identical twin of
/// VerifyPhoneController, kept as a SEPARATE controller (not reused)
/// because its verify() must call AuthRepository.verifyRecoveryOtp()
/// (-> /v1/recover), never verifyOtp() (-> /v1/register) — the two
/// endpoints reject each other's tokens by design.
class RecoveryVerifyController extends Notifier<RecoveryVerifyState> {
  static const int _expirySeconds = 5 * 60;

  Timer? _timer;

  @override
  RecoveryVerifyState build() {
    ref.onDispose(() => _timer?.cancel());
    _startCountdown();
    return const RecoveryVerifyState(secondsLeft: _expirySeconds);
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (state.secondsLeft <= 0) {
        t.cancel();
        return;
      }
      state = state.copyWith(secondsLeft: state.secondsLeft - 1);
    });
  }

  Future<bool> verify(String code) async {
    if (state.expired) return false;
    state = state.copyWith(verifying: true, clearError: true);
    final Result<Failure, void> result =
        await ref.read(authRepositoryProvider).verifyRecoveryOtp(code);
    switch (result) {
      case Ok<Failure, void>():
        state = state.copyWith(verifying: false, clearError: true);
        return true;
      case Err<Failure, void>(:final value):
        state = state.copyWith(verifying: false, errorMessage: value.message);
        return false;
    }
  }

  Future<void> resend() async {
    await ref.read(authRepositoryProvider).resendRecoveryOtp();
    state = const RecoveryVerifyState(secondsLeft: _expirySeconds);
    _startCountdown();
  }
}

final recoveryVerifyControllerProvider =
    NotifierProvider<RecoveryVerifyController, RecoveryVerifyState>(
  RecoveryVerifyController.new,
);
