import 'package:flutter/material.dart';

/// Centralized color tokens for the EduManage design system.
/// Avoid using hardcoded Color(0x...) or bare Colors.xxx in UI widgets.
class AppColors {
  AppColors._();

  // ── Primary Brand ──────────────────────────────────────────
  static const Color primary        = Color(0xFF1A56DB); // Rich blue
  static const Color primaryLight   = Color(0xFF3B82F6);
  static const Color primaryDark    = Color(0xFF1E3A8A);
  static const Color primarySubtle  = Color(0xFFEFF6FF);

  // ── Accent ────────────────────────────────────────────────
  static const Color accent         = Color(0xFF7C3AED); // Purple
  static const Color accentLight    = Color(0xFFA78BFA);
  static const Color accentSubtle   = Color(0xFFF5F3FF);

  // ── Roles ─────────────────────────────────────────────────
  static const Color adminColor     = Color(0xFF0EA5E9); // Sky
  static const Color adminLight     = Color(0xFFE0F2FE);
  static const Color teacherColor   = Color(0xFF10B981); // Emerald
  static const Color teacherLight   = Color(0xFFD1FAE5);
  static const Color studentColor   = Color(0xFF8B5CF6); // Violet
  static const Color studentLight   = Color(0xFFEDE9FE);
  static const Color parentColor    = Color(0xFFF59E0B); // Amber
  static const Color parentLight    = Color(0xFFFEF3C7);

  // ── Semantic ──────────────────────────────────────────────
  static const Color success        = Color(0xFF22C55E);
  static const Color successLight   = Color(0xFFDCFCE7);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningLight   = Color(0xFFFEF3C7);
  static const Color danger         = Color(0xFFEF4444);
  static const Color dangerLight    = Color(0xFFFEE2E2);
  static const Color info           = Color(0xFF0EA5E9);
  static const Color infoLight      = Color(0xFFE0F2FE);

  // ── Surface & Neutral ─────────────────────────────────────
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color background     = Color(0xFFF8FAFC);
  static const Color cardBg         = Color(0xFFFFFFFF);
  static const Color cardBorder     = Color(0xFFE2E8F0);
  static const Color border         = Color(0xFFCBD5E1);
  static const Color divider        = Color(0xFFE2E8F0);
  static const Color inputBg        = Color(0xFFF8FAFC);
  static const Color inputBorder    = Color(0xFFCBD5E1);
  static const Color chipBg         = Color(0xFFF1F5F9);

  // ── Typography Colors ─────────────────────────────────────
  static const Color textPrimary    = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary  = Color(0xFF64748B); // Slate 500
  static const Color textHint       = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted      = Color(0xFFCBD5E1);
  static const Color disabled       = Color(0xFFCBD5E1);
  static const Color onPrimary      = Color(0xFFFFFFFF);
  static const Color onDark         = Color(0xFFFFFFFF);
  static const Color overlay        = Color(0x990F172A);
  static const Color transparent    = Color(0x00000000);

  // ── Shimmer Loading Colors ────────────────────────────────
  static const Color shimmerBase      = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);

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

  // ── Card Shadow ───────────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D0F172A), // 5% alpha of 0xFF0F172A without precision loss
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x1A0F172A), // 10% alpha
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}
