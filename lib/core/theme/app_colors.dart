import 'package:flutter/material.dart';

/// Centralized color tokens for the EduManage design system.
///
/// All UI widgets, features, themes, and components must consume colors
/// from this single centralized definition to maintain brand consistency
/// and ensure rapid, dependable theming.
class AppColors {
  AppColors._();

  // ── Pure Base & Neutrals ────────────────────────────────────
  static const Color white          = Color(0xFFFFFFFF);
  static const Color black          = Color(0xFF000000);
  static const Color transparent    = Color(0x00000000);

  // ── Slate / Gray Scale ──────────────────────────────────────
  static const Color grey50         = Color(0xFFF8FAFC);
  static const Color grey100        = Color(0xFFF1F5F9);
  static const Color grey200        = Color(0xFFE2E8F0);
  static const Color grey300        = Color(0xFFCBD5E1);
  static const Color grey400        = Color(0xFF94A3B8);
  static const Color grey500        = Color(0xFF64748B);
  static const Color grey600        = Color(0xFF475569);
  static const Color grey700        = Color(0xFF334155);
  static const Color grey800        = Color(0xFF1E293B);
  static const Color grey900        = Color(0xFF0F172A);

  // Convenience Gray Aliases
  static const Color grey           = grey500;
  static const Color dark           = grey900;
  static const Color light          = grey100;

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

  // ── Semantic Feedback ─────────────────────────────────────
  static const Color success        = Color(0xFF22C55E);
  static const Color successLight   = Color(0xFFDCFCE7);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningLight   = Color(0xFFFEF3C7);
  static const Color danger         = Color(0xFFEF4444);
  static const Color dangerLight    = Color(0xFFFEE2E2);
  static const Color info           = Color(0xFF0EA5E9);
  static const Color infoLight      = Color(0xFFE0F2FE);

  // Semantic Aliases
  static const Color error          = danger;
  static const Color errorLight     = dangerLight;

  // ── Categories & Notice Types ──────────────────────────────
  static const Color categoryEvent   = Color(0xFF7C3AED); // Event purple
  static const Color categoryExam    = Color(0xFF1A56DB); // Exam blue
  static const Color categoryFinance = Color(0xFFE67E22); // Finance orange
  static const Color categoryHoliday = Color(0xFF059669); // Holiday emerald
  static const Color categoryGeneral = Color(0xFF6B7280); // General slate

  // ── Surface & Neutral Containers ───────────────────────────
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

  // ── Dark Mode Neutral & Surface Tokens ────────────────────
  static const Color darkBackground   = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface      = Color(0xFF1E293B); // Slate 800
  static const Color darkCardBg       = Color(0xFF1E293B);
  static const Color darkCardBorder   = Color(0xFF334155); // Slate 700
  static const Color darkBorder       = Color(0xFF334155);
  static const Color darkDivider      = Color(0xFF334155);
  static const Color darkInputBg      = Color(0xFF0F172A);
  static const Color darkInputBorder  = Color(0xFF334155);
  static const Color darkTextPrimary  = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextHint     = Color(0xFF64748B); // Slate 500

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

  static const LinearGradient financeGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ───────────────────────────────────────────────
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x080F172A), // 3% alpha
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D0F172A), // 5% alpha
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
