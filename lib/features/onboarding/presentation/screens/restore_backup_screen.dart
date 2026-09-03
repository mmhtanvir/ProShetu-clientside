import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/onboarding_providers.dart';

/// Non-destructive restore: OTP + the user-chosen Encryption ID (set
/// once at signup, see SetEncryptionIdScreen / AuthRepository's
/// setEncryptionId) decrypts the SAME identity that was backed up —
/// unlike RecoverAccountScreen, this does NOT mint a new identity, so
/// existing contacts stay trusted. The phone number is normally
/// already known (carried over from LoginScreen), so the only fields
/// the user ever sees here are the OTP and the Encryption ID; the
/// phone-entry step below only appears if this screen is somehow
/// reached without one.
class RestoreBackupScreen extends ConsumerStatefulWidget {
  const RestoreBackupScreen({super.key, this.initialPhone = ''});

  final String initialPhone;

  @override
  ConsumerState<RestoreBackupScreen> createState() =>
      _RestoreBackupScreenState();
}

class _RestoreBackupScreenState extends ConsumerState<RestoreBackupScreen> {
  String _phone = '';
  String? _phoneError;
  final TextEditingController _code = TextEditingController();
  final TextEditingController _encryptionId = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _phone = widget.initialPhone;
    if (_phone.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _encryptionId.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _phoneError = _phone.replaceAll(RegExp(r'\D'), '').length < 10
          ? 'Enter a valid phone number.'
          : null;
    });
    if (_phoneError != null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .startBackupRestore(phone: _phone.trim());
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is StateError ? e.message : e.toString();
      });
    }
  }

  Future<void> _restore() async {
    if (_code.text.length != 6 || _encryptionId.text.isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final Result<Failure, void> result =
        await ref.read(authRepositoryProvider).verifyBackupRestoreOtp(
              _code.text,
              encryptionId: _encryptionId.text,
              // The Encryption ID also wraps local storage on this
              // device — one secret, not two, per DeviceKeys.importFromBackup's
              // independent Argon2id derivation (own random salt).
              localPassword: _encryptionId.text,
            );
    if (!mounted) return;
    switch (result) {
      case Ok<Failure, void>():
        await ref.read(authRepositoryProvider).saveSession();
        final bool done =
            await ref.read(authRepositoryProvider).hasCompletedSecuritySetup();
        if (!mounted) return;
        context.goNamed(done ? AppRoutes.home : AppRoutes.setPin);
      case Err<Failure, void>(:final value):
        setState(() {
          _loading = false;
          _error = value.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Restore with Encryption ID')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Restores your existing account and contacts on this '
                  'device — not a new identity. Requires the Encryption '
                  'ID you set at signup.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!_codeSent) ...[
                  AppPhoneField(
                    label: 'Phone number',
                    hint: '555 0100',
                    errorText: _phoneError,
                    textInputAction: TextInputAction.done,
                    onChanged: (String v) => _phone = v,
                    onSubmitted: (_) => _sendCode(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Send code',
                    isLoading: _loading,
                    onPressed: _sendCode,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.danger),
                    ),
                  ],
                ] else ...[
                  Text(
                    'Code sent to $_phone.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _code,
                    label: '6-digit code',
                    hint: '123456',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _encryptionId,
                    label: 'Encryption ID',
                    hint: 'The secret you set on your other device',
                    obscureText: _obscure,
                    onChanged: (_) => setState(() {}),
                    suffix: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Restore account',
                    variant: AppButtonVariant.inverse,
                    pill: true,
                    isLoading: _loading,
                    onPressed: _code.text.length == 6 &&
                            _encryptionId.text.isNotEmpty
                        ? _restore
                        : null,
                  ),
                  AppButton(
                    label: 'Resend code',
                    variant: AppButtonVariant.ghost,
                    onPressed: () =>
                        ref.read(authRepositoryProvider).resendRecoveryOtp(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          context.goNamed(AppRoutes.recoverAccount),
                      child: const Text(
                        "Lost your Encryption ID? Start fresh",
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
