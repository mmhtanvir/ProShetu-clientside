import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/signup_controller.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_footer_link.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String? _nameError, _phoneError, _passwordError, _confirmError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _validate(AppLocalizations l10n) {
    setState(() {
      _nameError = _name.text.trim().isEmpty ? l10n.validationRequired : null;
      _phoneError = _phone.text.replaceAll(RegExp(r'\D'), '').length < 10
          ? l10n.validationPhoneInvalid
          : null;
      _passwordError =
          _password.text.length < 8 ? l10n.validationPasswordShort : null;
      _confirmError = _confirm.text != _password.text
          ? l10n.validationPasswordMismatch
          : null;
    });
    return [_nameError, _phoneError, _passwordError, _confirmError]
        .every((String? e) => e == null);
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!_validate(l10n)) return;

    final bool ok =
        await ref.read(signupControllerProvider.notifier).submit(
              displayName: _name.text.trim(),
              phone: _phone.text.trim(),
              password: _password.text,
            );
    if (ok && mounted) {
      context.goNamed(AppRoutes.verifyPhone, extra: _phone.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool loading = ref.watch(signupControllerProvider).isLoading;

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
                Text(l10n.authSignupTitle,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _name,
                  label: l10n.authDisplayName,
                  hint: l10n.authDisplayNameHint,
                  errorText: _nameError,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
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
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _confirm,
                  label: l10n.authConfirmPassword,
                  hint: l10n.authConfirmPasswordHint,
                  errorText: _confirmError,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: l10n.authSignUp,
                  variant: AppButtonVariant.inverse,
                  pill: true,
                  isLoading: loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthFooterLink(
                  prompt: l10n.authHaveAccount,
                  action: l10n.authLogInHere,
                  onTap: () => context.goNamed(AppRoutes.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
