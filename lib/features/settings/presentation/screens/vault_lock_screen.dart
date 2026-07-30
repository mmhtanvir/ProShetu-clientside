import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';

/// Vault gate: verifies the user's encryption PIN before showing
/// vault contents. The PIN never leaves this screen's state.
class VaultLockScreen extends ConsumerStatefulWidget {
  const VaultLockScreen({super.key});

  @override
  ConsumerState<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends ConsumerState<VaultLockScreen> {
  static const int _pinLength = 6;
  String _pin = '';
  bool _wrong = false;
  bool _checking = false;

  void _addDigit(String d) {
    if (_pin.length >= _pinLength) return;
    setState(() {
      _pin += d;
      _wrong = false;
    });
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _checking = true);
    final bool ok =
        await ref.read(authRepositoryProvider).verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      context.pushReplacementNamed(AppRoutes.vaultGallery);
    } else {
      setState(() {
        _pin = '';
        _wrong = true;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileVault)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.vaultEnterPin,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCodeSlots(
                      length: _pinLength, value: _pin, obscure: true),
                  if (_wrong) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.vaultWrongPin,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.danger),
                    ),
                  ],
                  const Spacer(),
                  if (_checking)
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
