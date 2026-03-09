import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF3F4EF5);
  static const Color primaryFaint = Color(0x203F4EF5);
  static const Color lime        = Color(0xFFDEF829);
  static const Color primaryLight = Color(0xFFEEF0FE);
  static const Color primaryDark  = Color(0xFF2A35C9);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning      = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error        = Color(0xFFF44336);
  static const Color errorLight   = Color(0xFFFFEBEE);

  // ── Neutral ──────────────────────────────────────────────────────────────
  static const Color background   = Color(0xFFF5F7FA);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color divider      = Color(0xFFF0F0F5);
  static const Color border       = Color(0xFFE5E7EB);
  static const Color inputBg      = Color(0xFFF9FAFB);
  static const Color neutralLight = Color(0xFFF3F4F6);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFF9CA3AF);
  static const Color textMuted     = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Avatar palette (for rider initials) ──────────────────────────────────
  static const List<Color> avatarColors = [
    Color(0xFF3F4EF5),
    Color(0xFF9C27B0),
    Color(0xFF009688),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
  ];
}
