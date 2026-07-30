import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/identity_doc_type.dart';
import '../controllers/identity_controller.dart';

/// "Congratulations" — document uploaded, account pending review.
class IdentitySuccessScreen extends ConsumerWidget {
  const IdentitySuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final IdentityDocType type = ref.watch(
          identityControllerProvider.select((s) => s.docType),
        ) ??
        IdentityDocType.nid;

    final String docName = switch (type) {
      IdentityDocType.nid => l10n.authNidOption,
      IdentityDocType.birthCertificate => l10n.authBirthCertOption,
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  ShaderMask(
                    shaderCallback: (Rect bounds) =>
                        AppColors.brandGradient.createShader(bounds),
                    child: const Icon(
                      Icons.verified_rounded,
                      size: 88,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.authCongratsTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.authCongratsBody(docName),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  AppButton(
                    label: l10n.commonContinue,
                    variant: AppButtonVariant.inverse,
                    pill: true,
                    // Signup continues straight into security setup —
                    // no login step for a freshly created account.
                    onPressed: () => context.goNamed(AppRoutes.setPin),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
