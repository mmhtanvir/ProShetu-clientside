import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/security_setup_controller.dart';

/// Mandatory step of first-run security setup: the secret that makes
/// logging in on a future new device possible at all. Without this,
/// a lost/replaced device has no non-destructive way back into the
/// same account (see RestoreBackupScreen) — so unlike Settings'
/// optional "Set Encryption ID" dialog, this one can't be skipped.
class SetEncryptionIdScreen extends ConsumerStatefulWidget {
  const SetEncryptionIdScreen({super.key});

  @override
  ConsumerState<SetEncryptionIdScreen> createState() =>
      _SetEncryptionIdScreenState();
}

class _SetEncryptionIdScreenState
    extends ConsumerState<SetEncryptionIdScreen> {
  final TextEditingController _id = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _canSubmit => _id.text.length >= 6 && _id.text == _confirm.text;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _error = null);
    final bool ok = await ref
        .read(securitySetupControllerProvider.notifier)
        .setEncryptionId(_id.text);
    if (!mounted) return;
    if (ok) {
      context.goNamed(AppRoutes.trustedContacts);
    } else {
      final Object? error = ref.read(securitySetupControllerProvider).error;
      setState(() {
        _error = error is Failure ? error.message : 'Could not save your Encryption ID.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool saving = ref.watch(securitySetupControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text('Set your Encryption ID',
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'A secret only you know. On a new device, your phone '
                  'number, the SMS code, and this Encryption ID are all '
                  "it takes to get back into this exact account — we "
                  "cannot recover it for you if you forget it.",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _id,
                  label: 'Encryption ID',
                  hint: 'At least 6 characters',
                  obscureText: _obscure,
                  onChanged: (_) => setState(() {}),
                  suffix: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _confirm,
                  label: 'Confirm Encryption ID',
                  obscureText: _obscure,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppInfoNote(
                  text: 'Write this down and keep it somewhere safe — it '
                      'never leaves this device unencrypted and we have '
                      'no way to reset it.',
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
                  label: 'Continue',
                  variant: AppButtonVariant.inverse,
                  pill: true,
                  isLoading: saving,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
