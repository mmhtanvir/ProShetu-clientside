import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../connectivity/presentation/providers/connectivity_providers.dart';
import '../../domain/sos_alert.dart';
import '../controllers/sos_controller.dart';
import 'sos_type_screen.dart';

/// Step 2: the alert form. Name/number/location are prefilled from
/// the profile (mock for now); `In Need` adds a "looking for" field.
class SosFormScreen extends ConsumerStatefulWidget {
  const SosFormScreen({super.key});

  @override
  ConsumerState<SosFormScreen> createState() => _SosFormScreenState();
}

class _SosFormScreenState extends ConsumerState<SosFormScreen> {
  late final TextEditingController _name;
  final TextEditingController _number =
      TextEditingController(text: '+88 01600-000000');
  final TextEditingController _location =
      TextEditingController(text: 'Dhanmondi Rd, Gulshan Ave');
  final TextEditingController _lookingFor = TextEditingController();
  final TextEditingController _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: ref.read(displayNameProvider));
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _location.dispose();
    _lookingFor.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit(SosType type) async {
    final bool ok =
        await ref.read(sosSubmitControllerProvider.notifier).submit(
              SosDraft(
                type: type,
                name: _name.text.trim(),
                number: _number.text.trim(),
                location: _location.text.trim(),
                lookingFor: _lookingFor.text.trim(),
                description: _description.text.trim(),
              ),
            );
    if (ok && mounted) context.goNamed(AppRoutes.sosSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final SosType type =
        ref.watch(sosTypeProvider) ?? SosType.naturalDisaster;
    final bool loading =
        ref.watch(sosSubmitControllerProvider).isLoading;
    final bool inNeed = type == SosType.inNeed;

    Widget optionalLabel(String base) => Text.rich(
          TextSpan(
            text: base,
            style: theme.textTheme.titleMedium,
            children: [
              TextSpan(
                text: '  ${l10n.sosOptionalSuffix}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sosCreateTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AppTextField(
                  label: l10n.sosTypeLabel,
                  controller: TextEditingController(
                      text: SosTypeScreen.typeLabel(l10n, type)),
                  enabled: false,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: l10n.sosName, controller: _name),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.sosNumber,
                  controller: _number,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.sosLocation,
                  controller: _location,
                  suffix: const Icon(Icons.edit_outlined, size: 18),
                ),
                const SizedBox(height: AppSpacing.md),
                if (inNeed) ...[
                  Text(l10n.sosLookingFor,
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  AppTextField(
                    controller: _lookingFor,
                    hint: l10n.sosLookingForHint,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                optionalLabel(l10n.sosDescription),
                const SizedBox(height: AppSpacing.xs),
                AppTextField(
                  controller: _description,
                  hint: l10n.sosDescriptionHint,
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: l10n.sosCreate,
                  variant: AppButtonVariant.inverse,
                  pill: true,
                  isLoading: loading,
                  onPressed: () => _submit(type),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
