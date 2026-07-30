import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/sos_controller.dart';

/// SOS created confirmation.
class SosSuccessScreen extends ConsumerWidget {
  const SosSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  ShaderMask(
                    shaderCallback: (Rect b) =>
                        AppColors.brandGradient.createShader(b),
                    child: const Icon(Icons.verified_rounded,
                        size: 88, color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.authCongratsTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.sosSuccessBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  AppButton(
                    label: l10n.navHome,
                    variant: AppButtonVariant.inverse,
                    pill: true,
                    onPressed: () {
                      ref.read(sosTypeProvider.notifier).reset();
                      context.goNamed(AppRoutes.home);
                    },
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
