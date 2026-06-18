import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Brand ──────────────────────────────────────────
  static const Color primary        = Color(0xFF1A56DB); // rich blue
  static const Color primaryLight   = Color(0xFF3B82F6);
  static const Color primaryDark    = Color(0xFF1E3A8A);

  // ── Accent ────────────────────────────────────────────────
  static const Color accent         = Color(0xFF7C3AED); // purple
  static const Color accentLight    = Color(0xFFA78BFA);

  // ── Roles ─────────────────────────────────────────────────
  static const Color adminColor    = Color(0xFF0EA5E9); // sky
  static const Color teacherColor  = Color(0xFF10B981); // emerald
  static const Color studentColor  = Color(0xFF8B5CF6); // violet

  // ── Semantic ──────────────────────────────────────────────
  static const Color success        = Color(0xFF22C55E);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color danger         = Color(0xFFEF4444);
  static const Color info           = Color(0xFF0EA5E9);

  // ── Neutral ───────────────────────────────────────────────
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color background     = Color(0xFFF8FAFC);
  static const Color cardBg         = Color(0xFFFFFFFF);
  static const Color divider        = Color(0xFFE2E8F0);

  static const Color textPrimary    = Color(0xFF0F172A);
  static const Color textSecondary  = Color(0xFF64748B);
  static const Color textHint       = Color(0xFF94A3B8);

  // ── Gradients ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF1A56DB), Color(0xFF7C3AED)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient adminGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient teacherGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient studentGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Card Shadow ──────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
  ];
}