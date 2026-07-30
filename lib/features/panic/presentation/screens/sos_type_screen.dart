import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/sos_alert.dart';
import '../controllers/sos_controller.dart';

/// Step 1: choose the SOS category.
class SosTypeScreen extends ConsumerWidget {
  const SosTypeScreen({super.key});

  static String typeLabel(AppLocalizations l10n, SosType type) =>
      switch (type) {
        SosType.naturalDisaster => l10n.sosTypeNatural,
        SosType.protestDistress => l10n.sosTypeProtest,
        SosType.inNeed => l10n.sosTypeInNeed,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SosType? selected = ref.watch(sosTypeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sosCreateTitle)),
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
                  for (final SosType type in SosType.values)
                    RadioListTile<SosType>(
                      value: type,
                      groupValue: selected,
                      onChanged: (SosType? v) {
                        if (v != null) {
                          ref.read(sosTypeProvider.notifier).select(v);
                        }
                      },
                      title: Text(typeLabel(l10n, type)),
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      dense: true,
                    ),
                  const Spacer(),
                  AppButton(
                    label: l10n.commonContinue,
                    variant: AppButtonVariant.inverse,
                    pill: true,
                    onPressed: selected == null
                        ? null
                        : () => context.pushNamed(AppRoutes.sosForm),
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
