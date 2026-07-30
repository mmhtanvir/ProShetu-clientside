import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../panic/domain/sos_alert.dart';
import 'sos_type_style.dart';

/// Builds the map pin used for [SosType] reports: a reporter-identity
/// avatar (matching [AppAvatar]'s color/initials) with a category
/// badge overlapping its base, the same composite shown in the design.
///
/// `GoogleMap` markers are native platform views and cannot embed a
/// live Flutter widget, so this rasterizes the composite once to a
/// PNG and hands it to `BitmapDescriptor.fromBytes`. Results are
/// cached per (name, type, pixel ratio) since they never change once
/// drawn — regenerating on every rebuild would repaint on the GPU
/// needlessly, which matters on the low-end/low-battery devices this
/// app targets.
abstract final class SosMarkerBitmap {
  static const double _width = 64;
  static const double _height = 84;
  static const double _avatarCenterX = _width / 2;
  static const double _avatarCenterY = 24;
  static const double _avatarRadius = 22;
  static const double _badgeCenterX = _width / 2;
  static const double _badgeCenterY = 60;
  static const double _badgeRadius = 16;

  /// Fraction of the bitmap that sits on the true lat/lng — the badge
  /// center, so the pulse [Circle] (drawn separately, geo-anchored)
  /// lines up with the category badge rather than the avatar above it.
  static const Offset anchor = Offset(
    _badgeCenterX / _width,
    _badgeCenterY / _height,
  );

  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> forReport({
    required String reporterName,
    required SosType type,
    required double devicePixelRatio,
  }) async {
    final String key = '$reporterName|$type|$devicePixelRatio';
    final BitmapDescriptor? cached = _cache[key];
    if (cached != null) return cached;

    final Color identityColor = AppAvatar.colorForName(reporterName);
    final String initials = AppAvatar.initialsForName(reporterName);
    final Color badgeColor = SosTypeStyle.color(type);
    final IconData badgeIcon = SosTypeStyle.icon(type);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, _width, _height),
    );
    canvas.scale(devicePixelRatio);

    // Avatar: translucent fill + solid ring, matching AppAvatar exactly.
    final Paint avatarFill = Paint()
      ..color = identityColor.withValues(alpha: 0.25);
    final Paint avatarRing = Paint()
      ..color = identityColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      const Offset(_avatarCenterX, _avatarCenterY),
      _avatarRadius,
      avatarFill,
    );
    canvas.drawCircle(
      const Offset(_avatarCenterX, _avatarCenterY),
      _avatarRadius - 1,
      avatarRing,
    );

    final TextPainter initialsPainter = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          color: identityColor,
          fontWeight: FontWeight.w700,
          fontSize: _avatarRadius * 0.72,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    initialsPainter.paint(
      canvas,
      Offset(
        _avatarCenterX - initialsPainter.width / 2,
        _avatarCenterY - initialsPainter.height / 2,
      ),
    );

    // Category badge: a small white ring separates it from the avatar
    // above so the two circles don't visually merge.
    final Paint badgeRing = Paint()..color = Colors.white;
    canvas.drawCircle(
      const Offset(_badgeCenterX, _badgeCenterY),
      _badgeRadius + 2,
      badgeRing,
    );
    final Paint badgeFill = Paint()..color = badgeColor;
    canvas.drawCircle(
      const Offset(_badgeCenterX, _badgeCenterY),
      _badgeRadius,
      badgeFill,
    );

    final TextPainter iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(badgeIcon.codePoint),
        style: TextStyle(
          fontSize: _badgeRadius * 1.1,
          fontFamily: badgeIcon.fontFamily,
          package: badgeIcon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        _badgeCenterX - iconPainter.width / 2,
        _badgeCenterY - iconPainter.height / 2,
      ),
    );

    final ui.Image image = await recorder.endRecording().toImage(
          (_width * devicePixelRatio).round(),
          (_height * devicePixelRatio).round(),
        );
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    // BitmapDescriptor.bytes() (the non-deprecated replacement) has open
    // upstream bugs on this plugin version — distorted size/aspect ratio,
    // or falling back to the default pin — on both Android and iOS.
    // fromBytes() is deprecated but reliable here; pinning to it with an
    // explicit logical `size` keeps the marker sharp and correctly scaled.
    // ignore: deprecated_member_use
    final BitmapDescriptor descriptor = BitmapDescriptor.fromBytes(
      bytes!.buffer.asUint8List(),
      size: const Size(_width, _height),
    );

    _cache[key] = descriptor;
    return descriptor;
  }
}
