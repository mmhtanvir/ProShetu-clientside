import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/security_setup_controller.dart';

/// Encryption PIN setup: 6 slots + custom numpad.
/// The entered digits are transient screen state; persistence goes
/// through [SecuritySetupController].
class SetPinScreen extends ConsumerStatefulWidget {
  const SetPinScreen({super.key});

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  static const int _pinLength = 6;
  String _pin = '';

  void _addDigit(String d) {
    if (_pin.length >= _pinLength) return;
    setState(() => _pin += d);
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    final bool ok = await ref
        .read(securitySetupControllerProvider.notifier)
        .savePin(_pin);
    if (ok && mounted) context.goNamed(AppRoutes.setEncryptionId);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool saving =
        ref.watch(securitySetupControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.pinTitle,
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.pinSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.pinChoose,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    label: l10n.pinChoose,
                    child: AppCodeSlots(
                      length: _pinLength,
                      value: _pin,
                      obscure: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppInfoNote(text: l10n.pinNote),
                  const Spacer(),
                  if (saving)
                    const AppLoading()
                  else
                    AppNumpad(
                      onDigit: _addDigit,
                      onBackspace: _backspace,
                      onSubmit: _submit,
                      submitEnabled: _pin.length == _pinLength,
                    ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
