import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../panic/domain/sos_alert.dart';
import '../../../panic/presentation/screens/sos_type_screen.dart';
import '../../domain/map_marker.dart';

/// Presents [MapDetailsSheet] as a centered card over a dimmed
/// backdrop.
///
/// Deliberately NOT `showAppBottomSheet`: the design shows this card
/// floating with margin on every side (top, bottom, left, right) over
/// a dimmed map, not a sheet anchored to the bottom edge with the
/// app's usual drag-handle chrome. If that reading of the design is
/// wrong, swap this for `showAppBottomSheet` — the card content
/// itself (`MapDetailsSheet`) is unaffected either way.
Future<void> showMapDetailsCard(BuildContext context, MapMarker marker) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (BuildContext ctx, __, ___) => Theme(
      data: AppTheme.light,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: MapDetailsSheet(marker: marker),
        ),
      ),
    ),
    transitionBuilder: (_, Animation<double> animation, __, Widget child) =>
        FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: child,
      ),
    ),
  );
}

/// Full detail view for a tapped map pin.
///
/// Rendered on the app's **light** theme regardless of the ambient
/// dark theme — matching the design, which floats a bright white card
/// over the dark, blurred map for contrast. Use [showMapDetailsCard]
/// to present it; it applies the light-theme override.
class MapDetailsSheet extends StatelessWidget {
  const MapDetailsSheet({required this.marker, super.key});

  final MapMarker marker;

  void _copyNumber(BuildContext context, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: marker.number));
    showAppSnackbar(context, l10n.mapNumberCopied,
        kind: AppSnackbarKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool inNeed = marker.type == SosType.inNeed;

    Widget row(String label, Widget value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: value,
                ),
              ),
            ],
          ),
        );

    Widget valueText(String text) => Text(
          text,
          textAlign: TextAlign.right,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );

    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SosTypeScreen.typeLabel(l10n, marker.type),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          row(l10n.mapDetailsCreatedBy, valueText(marker.reporterName)),
          row(
            l10n.sosNumber,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                valueText(marker.number),
                const SizedBox(width: AppSpacing.xxs),
                Semantics(
                  button: true,
                  label: l10n.mapDetailsCopyNumber,
                  child: InkWell(
                    borderRadius: AppRadius.smAll,
                    onTap: () => _copyNumber(context, l10n),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          row(l10n.sosLocation, valueText(marker.location)),
          if (inNeed && marker.lookingFor.isNotEmpty)
            row(l10n.mapDetailsLookingFor, valueText(marker.lookingFor)),
          if (marker.description.isNotEmpty)
            row(l10n.sosDescription, valueText(marker.description)),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.commonBack,
            variant: AppButtonVariant.inverse,
            pill: true,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
