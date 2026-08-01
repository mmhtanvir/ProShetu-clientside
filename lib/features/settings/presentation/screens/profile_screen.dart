import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../connectivity/presentation/providers/connectivity_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../widgets/settings_tile.dart';

/// Profile & settings hub.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).clearSession();
    if (context.mounted) context.goNamed(AppRoutes.login);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool confirmed = await showAppConfirmDialog(
      context,
      title: l10n.profileDeleteConfirmTitle,
      message: l10n.profileDeleteConfirmBody,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!confirmed) return;
    // TODO(backend): full account + key deletion. Session-only for now.
    await ref.read(authRepositoryProvider).clearSession();
    if (context.mounted) context.goNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String name = ref.watch(displayNameProvider).valueOrNull ?? '';
    final String phone = ref.watch(myPhoneProvider).valueOrNull ?? '';

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(
              top: AppSpacing.lg, bottom: AppSpacing.xs),
          child: Text(
            title,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Row(
                  children: [
                    AppAvatar(name: name, size: 48),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: theme.textTheme.titleLarge),
                          Text(
                            phone,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_empty_rounded,
                              size: 12, color: AppColors.warning),
                          const SizedBox(width: 3),
                          Text(
                            l10n.profileKycPendingReview,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.warning, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Vault entry — visually elevated.
                Material(
                  color: AppColors.surfaceRaisedDark,
                  borderRadius: AppRadius.lgAll,
                  child: InkWell(
                    borderRadius: AppRadius.lgAll,
                    onTap: () => context.pushNamed(AppRoutes.vaultLock),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(
                            color: AppColors.primary
                                .withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(l10n.profileVault,
                                style: theme.textTheme.titleMedium),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color:
                                  theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
                section(l10n.profileSecuritySection),
                SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: l10n.profileEncryptionKeys,
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.xs),
                SettingsTile(
                  icon: Icons.devices_rounded,
                  title: l10n.profileTrustedDevices,
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.xs),
                SettingsTile(
                  icon: Icons.timeline_rounded,
                  title: l10n.profileActivityLog,
                  onTap: () {},
                ),
                section(l10n.profilePrefsSection),
                SettingsTile(
                  icon: Icons.language_rounded,
                  title: l10n.profileLanguage,
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.xs),
                SettingsTile(
                  icon: Icons.palette_outlined,
                  title: l10n.profileAppearance,
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.xs),
                SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.profileNotifications,
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.lg),
                SettingsTile(
                  icon: Icons.logout_rounded,
                  title: l10n.profileLogout,
                  onTap: () => _logout(context, ref),
                ),
                const SizedBox(height: AppSpacing.xs),
                SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: l10n.profileDeleteAccount,
                  danger: true,
                  onTap: () => _deleteAccount(context, ref),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
