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

/// Choose NID (2 photos) or Birth Certificate (1 photo).
class IdentityChoiceScreen extends ConsumerWidget {
  const IdentityChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final IdentityDocType? selected =
        ref.watch(identityControllerProvider.select((s) => s.docType));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.goNamed(AppRoutes.signup),
        ),
        title: Text(l10n.authIdentityTitle),
      ),
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
                  Text(
                    l10n.authIdentityIntro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final IdentityDocType type
                      in IdentityDocType.values) ...[
                    RadioListTile<IdentityDocType>(
                      value: type,
                      groupValue: selected,
                      onChanged: (IdentityDocType? v) {
                        if (v != null) {
                          ref
                              .read(identityControllerProvider.notifier)
                              .selectDocType(v);
                        }
                      },
                      title: Text(
                        switch (type) {
                          IdentityDocType.nid => l10n.authNidOption,
                          IdentityDocType.birthCertificate =>
                            l10n.authBirthCertOption,
                        },
                        style: theme.textTheme.bodyLarge,
                      ),
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                    ),
                  ],
                  const Spacer(),
                  AppButton(
                    label: l10n.commonContinue,
                    variant: AppButtonVariant.inverse,
                    pill: true,
                    onPressed: selected == null
                        ? null
                        : () => context.pushNamed(AppRoutes.identityCapture),
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
