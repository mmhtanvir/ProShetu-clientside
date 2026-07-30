import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../panic/domain/sos_alert.dart';

/// Visual language for [SosType], shared by the map pin bitmap and the
/// marker detail sheet so both always agree on color + glyph.
///
/// NOTE: the source Figma pins use custom illustrated glyphs we don't
/// have as assets; these are the closest Material equivalents. Swap
/// in real icon assets here once exported from Figma.
abstract final class SosTypeStyle {
  static Color color(SosType type) => switch (type) {
        SosType.naturalDisaster => AppColors.danger,
        SosType.protestDistress => AppColors.danger,
        SosType.inNeed => AppColors.warning,
      };

  static IconData icon(SosType type) => switch (type) {
        SosType.naturalDisaster => Icons.warning_amber_rounded,
        SosType.protestDistress => Icons.pan_tool_rounded,
        SosType.inNeed => Icons.bloodtype_rounded,
      };
}
