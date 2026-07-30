import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_providers.dart';

class VerifyPhoneState extends Equatable {
  const VerifyPhoneState({
    required this.secondsLeft,
    this.verifying = false,
    this.invalidCode = false,
  });

  final int secondsLeft;
  final bool verifying;
  final bool invalidCode;

  bool get expired => secondsLeft <= 0;

  String get timeLabel {
    final int m = secondsLeft ~/ 60;
    final int s = secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  VerifyPhoneState copyWith(
          {int? secondsLeft, bool? verifying, bool? invalidCode}) =>
      VerifyPhoneState(
        secondsLeft: secondsLeft ?? this.secondsLeft,
        verifying: verifying ?? this.verifying,
        invalidCode: invalidCode ?? this.invalidCode,
      );

  @override
  List<Object?> get props => [secondsLeft, verifying, invalidCode];
}

/// OTP verification: owns the expiry countdown and the verify call.
/// AutoDispose ensures the timer dies with the screen.
class VerifyPhoneController extends AutoDisposeNotifier<VerifyPhoneState> {
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
    state = state.copyWith(verifying: true, invalidCode: false);
    final bool ok = await ref.read(authRepositoryProvider).verifyOtp(code);
    state = state.copyWith(verifying: false, invalidCode: !ok);
    return ok;
  }

  Future<void> resend() async {
    await ref.read(authRepositoryProvider).resendOtp();
    state = const VerifyPhoneState(secondsLeft: _expirySeconds);
    _startCountdown();
  }
}

final verifyPhoneControllerProvider =
    AutoDisposeNotifierProvider<VerifyPhoneController, VerifyPhoneState>(
  VerifyPhoneController.new,
);
