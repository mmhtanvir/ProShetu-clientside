import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../providers/onboarding_providers.dart';

class VerifyPhoneState extends Equatable {
  const VerifyPhoneState({
    required this.secondsLeft,
    this.verifying = false,
    this.errorMessage,
  });

  final int secondsLeft;
  final bool verifying;

  /// The backend's real failure message (wrong/expired code, phone
  /// already registered, network error, ...) — shown as-is rather
  /// than collapsed into one generic "invalid code" string, so a
  /// duplicate-number signup reads as exactly that, not as a typo.
  final String? errorMessage;

  bool get expired => secondsLeft <= 0;

  String get timeLabel {
    final int m = secondsLeft ~/ 60;
    final int s = secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  VerifyPhoneState copyWith({
    int? secondsLeft,
    bool? verifying,
    String? errorMessage,
    bool clearError = false,
  }) =>
      VerifyPhoneState(
        secondsLeft: secondsLeft ?? this.secondsLeft,
        verifying: verifying ?? this.verifying,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [secondsLeft, verifying, errorMessage];
}

/// OTP verification: owns the expiry countdown and the verify call.
/// Auto-dispose is the default in Riverpod 3, so the timer dies with the screen.
class VerifyPhoneController extends Notifier<VerifyPhoneState> {
  static const int _expirySeconds = 5 * 60;

  Timer? _timer;

  @override
  VerifyPhoneState build() {
    ref.onDispose(() => _timer?.cancel());
    _startCountdown();
    return const VerifyPhoneState(secondsLeft: _expirySeconds);
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
        await ref.read(authRepositoryProvider).verifyOtp(code);
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
    await ref.read(authRepositoryProvider).resendOtp();
    state = const VerifyPhoneState(secondsLeft: _expirySeconds);
    _startCountdown();
  }
}

final verifyPhoneControllerProvider =
    NotifierProvider<VerifyPhoneController, VerifyPhoneState>(
  VerifyPhoneController.new,
);
