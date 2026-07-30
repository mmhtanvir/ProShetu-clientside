import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Initials avatar with optional online dot.
///
/// Offline-first: no network images, no decode cost. Background color
/// is derived deterministically from the name so the same person is
/// always the same color.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.name,
    this.size = 40,
    this.online = false,
    super.key,
  });

  final String name;
  final double size;
  final bool online;

  static const List<Color> _palette = [
    Color(0xFF7B7FF2),
    Color(0xFF4AA8F0),
    Color(0xFF34C77B),
    Color(0xFFF5B93E),
    Color(0xFFE07856),
    Color(0xFF9C6ADE),
  ];

  /// Deterministic per-name color, exposed so other renderers (e.g. the
  /// map's rasterized marker bitmaps, which can't host this widget
  /// directly) draw the exact same identity color as this widget.
  static Color colorForName(String name) =>
      _palette[name.hashCode.abs() % _palette.length];

  /// Same initials rule as this widget, exposed for reuse.
  static String initialsForName(String name) {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get _initials => initialsForName(name);

  @override
  Widget build(BuildContext context) {
    final Color bg = colorForName(name);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: bg, width: 1.5),
            ),
            child: Text(
              _initials,
              style: TextStyle(
                color: bg,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.36,
              ),
            ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.backgroundDark,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
