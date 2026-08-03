import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/login_controller.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_footer_link.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  String? _phoneError, _passwordError;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() {
      _phoneError =
          _phone.text.trim().isEmpty ? l10n.validationRequired : null;
      _passwordError =
          _password.text.isEmpty ? l10n.validationRequired : null;
    });
    if (_phoneError != null || _passwordError != null) return;

    final PostLoginDestination? dest =
        await ref.read(loginControllerProvider.notifier).submit(
              phone: _phone.text.trim(),
              password: _password.text,
            );
    if (!mounted || dest == null) return;
    switch (dest) {
      case PostLoginDestination.setPin:
        context.goNamed(AppRoutes.setPin);
      case PostLoginDestination.home:
        context.goNamed(AppRoutes.home);
    }
  }

  Future<void> _offerRecovery(AppLocalizations l10n) async {
    await showAppBottomSheet<void>(
      context,
      builder: (BuildContext sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.authNoIdentityTitle,
                    style: Theme.of(sheetContext).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.authNoIdentityMessage,
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                      color: Theme.of(sheetContext)
                          .colorScheme
                          .onSurfaceVariant),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.key_rounded),
            title: const Text('Restore with Encryption ID'),
            subtitle: const Text(
                'Keeps your existing account and contacts (recommended)'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.goNamed(AppRoutes.restoreBackup);
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh_rounded),
            title: Text(l10n.authRecoveryTitle),
            subtitle: const Text(
                'Starts over with a new identity — old messages unreadable'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.goNamed(AppRoutes.recoverAccount);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool loading = ref.watch(loginControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(loginControllerProvider,
        (AsyncValue<void>? previous, AsyncValue<void> next) {
      final Object? error = next.error;
      if (error == null) return;
      final String message =
          error is StateError ? error.message : error.toString();
      // DeviceKeys.unlock's specific "nothing stored" failure — the
      // password itself may well be correct, there's just no local
      // identity to check it against (fresh install / new device).
      // A plain error toast is a dead end here, so offer the one
      // path that actually gets the user back in.
      if (message == 'No identity on this device') {
        _offerRecovery(l10n);
        return;
      }
      showAppSnackbar(context, message, kind: AppSnackbarKind.error);
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const AuthBrandHeader(),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.authLoginWelcome,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _phone,
                  label: l10n.authPhoneNumber,
                  hint: l10n.authPhoneHint,
                  errorText: _phoneError,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _password,
                  label: l10n.authPassword,
                  hint: l10n.authPasswordHint,
                  errorText: _passwordError,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  suffix: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.goNamed(AppRoutes.recoverAccount),
                    child: Text(l10n.authForgotPassword),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.authLogin,
                  variant: AppButtonVariant.inverse,
                  pill: true,
                  isLoading: loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthFooterLink(
                  prompt: l10n.authNoAccount,
                  action: l10n.authSignUpHere,
                  onTap: () => context.goNamed(AppRoutes.signup),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
