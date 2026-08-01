import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// First step of account recovery: phone entry only. The real warning
/// and the destructive action itself live on RecoveryConfirmScreen —
/// this screen exists purely to collect the phone number that screen
/// (and the SMS re-verification behind it) needs.
class RecoverAccountScreen extends StatefulWidget {
  const RecoverAccountScreen({super.key});

  @override
  State<RecoverAccountScreen> createState() => _RecoverAccountScreenState();
}

class _RecoverAccountScreenState extends State<RecoverAccountScreen> {
  String _phone = '';
  String? _phoneError;

  void _continue() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() {
      _phoneError = _phone.replaceAll(RegExp(r'\D'), '').length < 10
          ? l10n.validationPhoneInvalid
          : null;
    });
    if (_phoneError != null) return;
    context.goNamed(AppRoutes.recoveryConfirm, extra: _phone.trim());
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

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
                Text(
                  l10n.authRecoveryPhoneIntro,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPhoneField(
                  label: l10n.authPhoneNumber,
                  hint: l10n.authPhoneHint,
                  errorText: _phoneError,
                  textInputAction: TextInputAction.done,
                  onChanged: (String value) => _phone = value,
                  onSubmitted: (_) => _continue(),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: l10n.commonContinue,
                  variant: AppButtonVariant.inverse,
                  pill: true,
                  onPressed: _continue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
