import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/verify_phone_controller.dart';

/// OTP entry. A hidden text field owns the input (so the system
/// keyboard, paste and SMS autofill all work); [AppCodeSlots] renders
/// its value.
class VerifyPhoneScreen extends ConsumerStatefulWidget {
  const VerifyPhoneScreen({required this.phone, super.key});

  final String phone;

  @override
  ConsumerState<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends ConsumerState<VerifyPhoneScreen> {
  final TextEditingController _code = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) return;
    final bool ok = await ref
        .read(verifyPhoneControllerProvider.notifier)
        .verify(_code.text);
    if (ok && mounted) context.goNamed(AppRoutes.identityChoice);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final VerifyPhoneState state = ref.watch(verifyPhoneControllerProvider);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authVerifyPhoneTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  state.expired
                      ? l10n.authOtpExpired
                      : l10n.authOtpSentTo(widget.phone, state.timeLabel),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                GestureDetector(
                  onTap: () {
                    if (_focus.hasFocus) {
                      // Focus never changes here, so requestFocus() alone
                      // is a no-op — that's what leaves the keyboard stuck
                      // closed after it's dismissed once (back button,
                      // swipe-down) while the hidden field keeps focus.
                      // Ask the platform to show it directly instead.
                      SystemChannels.textInput
                          .invokeMethod<void>('TextInput.show');
                    } else {
                      _focus.requestFocus();
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Invisible input driving the slots.
                      Opacity(
                        opacity: 0,
                        child: SizedBox(
                          height: 1,
                          child: TextField(
                            controller: _code,
                            focusNode: _focus,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      AppCodeSlots(length: 6, value: _code.text),
                    ],
                  ),
                ),
                if (state.invalidCode) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.authOtpInvalid,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: l10n.authVerifyContinue,
                  variant: AppButtonVariant.inverse,
                  pill: true,
                  isLoading: state.verifying,
                  onPressed: _code.text.length == 6 && !state.expired
                      ? _verify
                      : null,
                ),
                AppButton(
                  label: l10n.authResendCode,
                  variant: AppButtonVariant.ghost,
                  onPressed: () {
                    _code.clear();
                    ref
                        .read(verifyPhoneControllerProvider.notifier)
                        .resend();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
