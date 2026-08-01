import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/recovery_confirm_controller.dart';

/// The mandatory warning step of account recovery. Real content, not
/// a footnote: recovering access mints a brand-new device keypair,
/// which silently makes every locally-stored message/session
/// undecryptable and requires every existing contact to re-pair. The
/// checkbox below physically gates the only way past this screen, and
/// the new-password fields live on the SAME screen so the warning and
/// the destructive action can't be separated by navigation.
class RecoveryConfirmScreen extends ConsumerStatefulWidget {
  const RecoveryConfirmScreen({required this.phone, super.key});

  final String phone;

  @override
  ConsumerState<RecoveryConfirmScreen> createState() =>
      _RecoveryConfirmScreenState();
}

class _RecoveryConfirmScreenState
    extends ConsumerState<RecoveryConfirmScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _understood = false;

  String? _passwordError, _confirmError;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _validate(AppLocalizations l10n) {
    setState(() {
      _passwordError =
          _password.text.length < 8 ? l10n.validationPasswordShort : null;
      _confirmError = _confirm.text != _password.text
          ? l10n.validationPasswordMismatch
          : null;
    });
    return _passwordError == null && _confirmError == null;
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!_understood || !_validate(l10n)) return;

    final bool ok = await ref
        .read(recoveryConfirmControllerProvider.notifier)
        .submit(phone: widget.phone, password: _password.text);
    if (ok && mounted) {
      context.goNamed(AppRoutes.recoveryVerify, extra: widget.phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool loading =
        ref.watch(recoveryConfirmControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(recoveryConfirmControllerProvider,
        (AsyncValue<void>? previous, AsyncValue<void> next) {
      final Object? error = next.error;
      if (error == null) return;
      showAppSnackbar(
        context,
        error is StateError ? error.message : error.toString(),
        kind: AppSnackbarKind.error,
      );
    });

    final bool canSubmit = _understood &&
        _password.text.isNotEmpty &&
        _confirm.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authRecoveryTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.authRecoveryWarningTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.authRecoveryWarningBody,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: () => setState(() => _understood = !_understood),
                  borderRadius: AppRadius.mdAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _understood,
                          onChanged: (bool? v) =>
                              setState(() => _understood = v ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              l10n.authRecoveryCheckbox,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _password,
                  label: l10n.authRecoveryNewPassword,
                  hint: l10n.authRecoveryNewPasswordHint,
                  errorText: _passwordError,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  suffix: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _confirm,
                  label: l10n.authConfirmPassword,
                  hint: l10n.authConfirmPasswordHint,
                  errorText: _confirmError,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  suffix: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: l10n.authRecoveryContinue,
                  variant: AppButtonVariant.danger,
                  pill: true,
                  isLoading: loading,
                  onPressed: canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
