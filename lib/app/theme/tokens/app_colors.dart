import 'package:flutter/material.dart';

/// Semantic color tokens for ProShetu.
///
/// Dark-first palette tuned for OLED battery savings (true near-black
/// surfaces) and readability under stress. Widgets must never hardcode
/// colors — always consume these tokens (usually via [Theme]).
abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────
  /// Primary brand indigo (top of the shield gradient).
  static const Color primary = Color(0xFF7B7FF2);

  /// Deeper indigo (bottom of the shield gradient / pressed states).
  static const Color primaryDeep = Color(0xFF5155E5);

  /// Gradient used by brand marks and primary CTAs.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryDeep],
  );

  // ── Dark surfaces (default theme) ────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0A0A0C);
  static const Color surfaceDark = Color(0xFF121216);
  static const Color surfaceRaisedDark = Color(0xFF1A1A20);
  static const Color borderDark = Color(0xFF26262E);

  // ── Light surfaces ───────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF7F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE3E3EA);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF4F4F6);
  static const Color textSecondaryDark = Color(0xFF9A9AA6);
  static const Color textDisabledDark = Color(0xFF55555F);
  static const Color textPrimaryLight = Color(0xFF15151A);
  static const Color textSecondaryLight = Color(0xFF5C5C68);

  // ── Status ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34C77B);
  static const Color warning = Color(0xFFF5B93E);

  /// Danger / panic. Reserved for destructive + emergency actions only.
  static const Color danger = Color(0xFFEF4B55);

  static const Color info = Color(0xFF4AA8F0);

  // ── Connectivity states (mesh / offline UX) ──────────────────────────
  static const Color online = success;
  static const Color meshOnly = warning;
  static const Color offline = textSecondaryDark;
}
