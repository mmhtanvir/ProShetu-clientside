import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/security_setup_controller.dart';

/// Add up to three trusted contacts; at least one is required to
/// complete profile setup.
class TrustedContactsScreen extends ConsumerStatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  ConsumerState<TrustedContactsScreen> createState() =>
      _TrustedContactsScreenState();
}

class _TrustedContactsScreenState
    extends ConsumerState<TrustedContactsScreen> {
  static const int _slots = 3;

  late final List<TextEditingController> _controllers =
      List.generate(_slots, (_) => TextEditingController());

  bool get _hasAtLeastOne =>
      _controllers.any((TextEditingController c) => c.text.trim().isNotEmpty);

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final bool ok = await ref
        .read(securitySetupControllerProvider.notifier)
        .saveTrustedContacts(
          _controllers.map((TextEditingController c) => c.text).toList(),
        );
    if (ok && mounted) context.goNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool saving =
        ref.watch(securitySetupControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(l10n.trustedTitle,
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.trustedSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (int i = 0; i < _slots; i++) ...[
                  AppTextField(
                    controller: _controllers[i],
                    label: l10n
                        .trustedContactLabel('0${i + 1}'),
                    hint: l10n.trustedContactHint,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppInfoNote(text: l10n.trustedNote),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.trustedAdd,
                  variant: AppButtonVariant.inverse,
                  pill: true,
                  isLoading: saving,
                  onPressed: _hasAtLeastOne ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
