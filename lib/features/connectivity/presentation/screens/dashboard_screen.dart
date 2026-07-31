import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../infrastructure/network/network_providers.dart';
import '../../../coordination/domain/crisis_alert.dart';
import '../../../hazards/presentation/providers/hazard_providers.dart';
import '../providers/connectivity_providers.dart';
import '../widgets/alert_carousel.dart';
import '../widgets/map_preview.dart';
import '../widgets/mesh_status_card.dart';
import '../widgets/status_tile.dart';

/// Home dashboard: greeting, mesh status, connectivity tiles,
/// active alerts, map preview.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting(AppLocalizations l10n) {
    final int hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String name = ref.watch(displayNameProvider);
    final statusAsync = ref.watch(networkStatusProvider);
    final peersAsync = ref.watch(nearbyPeersProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    final AsyncValue<List<CrisisAlert>> hazardAlerts =
        ref.watch(hazardAlertsProvider('BD'));
    // Loading/error both resolve to an empty list rather than
    // silently falling back to the mock alerts — showing stale mock
    // data as if it were a live flood/earthquake feed would be worse
    // than showing nothing while it loads or if the fetch failed.
    final List<CrisisAlert> alerts = hazardAlerts.valueOrNull ?? const [];

    final String stamp =
        DateFormat('h:mm a  |  dd MMM yyyy').format(DateTime.now());

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(l10n),
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          Text(name,
                              style: theme.textTheme.headlineSmall),
                        ],
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: () {},
                      icon:
                          const Icon(Icons.notifications_none_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(l10n.dashNetworkStatus,
                        style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      stamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                statusAsync.when(
                  loading: () => const SizedBox(
                      height: 96, child: AppLoading()),
                  error: (_, __) => AppStatusView.error(
                      title: l10n.errorGenericTitle),
                  data: (status) => MeshStatusCard(
                    status: status,
                    peers: peersAsync.value ?? const [],
                    onConnect: () =>
                        context.pushNamed(AppRoutes.nearbyMesh),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: connectivityAsync.when(
                        // Real, live network state (connectivity_plus) —
                        // not the mock MeshRepository.internetOnline bit.
                        data: (results) {
                          final ConnectionKind kind =
                              connectionKindOf(results);
                          final (String label, Color color) = switch (kind) {
                            ConnectionKind.wifi => (
                                'Wi-Fi',
                                AppColors.online
                              ),
                            ConnectionKind.mobile => (
                                'Mobile data',
                                AppColors.online
                              ),
                            ConnectionKind.offline => (
                                l10n.statusOffline,
                                AppColors.danger
                              ),
                            ConnectionKind.other => (
                                l10n.statusOnline,
                                AppColors.online
                              ),
                          };
                          return StatusTile(
                            icon: kind == ConnectionKind.wifi
                                ? Icons.wifi_rounded
                                : Icons.public_rounded,
                            title: l10n.dashInternet,
                            stateLabel: label,
                            stateColor: color,
                          );
                        },
                        loading: () => StatusTile(
                          icon: Icons.public_rounded,
                          title: l10n.dashInternet,
                          stateLabel: '…',
                          stateColor: AppColors.warning,
                        ),
                        error: (_, __) => StatusTile(
                          icon: Icons.public_rounded,
                          title: l10n.dashInternet,
                          stateLabel: l10n.statusOffline,
                          stateColor: AppColors.danger,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: statusAsync.maybeWhen(
                        data: (status) => StatusTile(
                          icon: Icons.location_on_outlined,
                          title: l10n.dashGps,
                          stateLabel: status.gpsLocked
                              ? l10n.statusLocked
                              : l10n.statusOffline,
                          stateColor: status.gpsLocked
                              ? AppColors.online
                              : AppColors.warning,
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.dashActiveAlert,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                AlertCarousel(alerts: alerts),
                const SizedBox(height: AppSpacing.lg),
                const MapPreview(),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
