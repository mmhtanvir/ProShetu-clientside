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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool loading = ref.watch(loginControllerProvider).isLoading;

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
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xl),
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
