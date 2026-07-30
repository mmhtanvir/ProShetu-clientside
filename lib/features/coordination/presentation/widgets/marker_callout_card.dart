import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../panic/domain/sos_alert.dart';
import '../../../panic/presentation/screens/sos_type_screen.dart';
import '../../domain/map_marker.dart';

/// Floating preview bubble that appears above a tapped map pin: who
/// reported it, how long ago, and its category. Tapping the bubble
/// opens the full [MapDetailsSheet].
///
/// Positioned by the map screen at the marker's on-screen coordinate
/// (via `GoogleMapController.getScreenCoordinate`) since GoogleMap's
/// built-in InfoWindow can't be restyled to this dark card design.
class MarkerCalloutCard extends StatelessWidget {
  const MarkerCalloutCard({required this.marker, this.onTap, super.key});

  final MapMarker marker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(name: marker.reporterName, size: 40),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          marker.reporterName,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        marker.ageLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    SosTypeScreen.typeLabel(l10n, marker.type),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
