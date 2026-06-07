import 'package:flutter/material.dart';

@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  // Display
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  // Headline
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  // Title
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  // Body
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  // Label
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;
  // Custom
  final TextStyle button;
  final TextStyle caption;

  const AppTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
    required this.button,
    required this.caption,
  });

  // ── Dark Preset ──────────────────────────────────────────────
  static const dark = AppTypography(
    // — Display (white on dark) —
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w600,
      height: 1.12,
      fontFamily: 'Inter',
      color: Color(0xFFF8FAFC),
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 1.16,
      fontFamily: 'Inter',
      color: Color(0xFFF8FAFC),
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 1.22,
      fontFamily: 'Inter',
      color: Color(0xFFF8FAFC),
    ),

    // — Headline —
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.25,
      fontFamily: 'Inter',
      color: Color(0xFFF8FAFC),
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 1.29,
      fontFamily: 'Inter',
      color: Color(0xFFF8FAFC),
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
      fontFamily: 'Inter',
      color: Color(0xFFF8FAFC),
    ),

    // — Title —
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.27,
      fontFamily: 'Inter',
      color: Color(0xFFF8FAFC),
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
      letterSpacing: 0.15,
      fontFamily: 'Inter',
      color: Color(0xFFF8FAFC),
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.1,
      fontFamily: 'Inter',
      color: Color(0xFFF8FAFC),
    ),

    // — Body —
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 0.5,
      fontFamily: 'Inter',
      color: Color(0xFFCBD5E1),
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
      fontFamily: 'Inter',
      color: Color(0xFFCBD5E1),
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
      fontFamily: 'Inter',
      color: Color(0xFF94A3B8),
    ),

    // — Label —
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.1,
      fontFamily: 'Inter',
      color: Color(0xFFCBD5E1),
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.5,
      fontFamily: 'Inter',
      color: Color(0xFF94A3B8),
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.45,
      letterSpacing: 0.5,
      fontFamily: 'Inter',
      color: Color(0xFF64748B),
    ),

    // — Custom —
    button: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.42,
      letterSpacing: 0.1,
      fontFamily: 'Inter',
      color: Color(0xFFFFFFFF),
    ),
    caption: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
      fontFamily: 'Inter',
      color: Color(0xFF94A3B8),
    ),
  );
  // ── LIGHT PRESET ─────────────────────────────────────────────
  // Same font sizes, weights, heights — only colors flipped for dark text on white
  static const light = AppTypography(
    // Display — slate-900
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w600,
      height: 1.12,
      fontFamily: 'Inter',
      color: Color(0xFF0F172A),
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 1.16,
      fontFamily: 'Inter',
      color: Color(0xFF0F172A),
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 1.22,
      fontFamily: 'Inter',
      color: Color(0xFF0F172A),
    ),

    // Headline — slate-900
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.25,
      fontFamily: 'Inter',
      color: Color(0xFF0F172A),
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 1.29,
      fontFamily: 'Inter',
      color: Color(0xFF0F172A),
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
      fontFamily: 'Inter',
      color: Color(0xFF0F172A),
    ),

    // Title — slate-900
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.27,
      fontFamily: 'Inter',
      color: Color(0xFF0F172A),
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.50,
      letterSpacing: 0.15,
      fontFamily: 'Inter',
      color: Color(0xFF0F172A),
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.10,
      fontFamily: 'Inter',
      color: Color(0xFF0F172A),
    ),

    // Body — slate-700 for large, slate-500 for small
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.50,
      letterSpacing: 0.50,
      fontFamily: 'Inter',
      color: Color(0xFF334155),
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
      fontFamily: 'Inter',
      color: Color(0xFF334155),
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.40,
      fontFamily: 'Inter',
      color: Color(0xFF64748B),
    ),

    // Label — slate-700 / slate-500 / slate-400
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.10,
      fontFamily: 'Inter',
      color: Color(0xFF334155),
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.50,
      fontFamily: 'Inter',
      color: Color(0xFF64748B),
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.45,
      letterSpacing: 0.50,
      fontFamily: 'Inter',
      color: Color(0xFF94A3B8),
    ),

    // Button — always white (sits on colored button backgrounds)
    button: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.42,
      letterSpacing: 0.10,
      fontFamily: 'Inter',
      color: Color(0xFFFFFFFF),
    ),

    // Caption — slate-500
    caption: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.40,
      fontFamily: 'Inter',
      color: Color(0xFF64748B),
    ),
  );
  // ── copyWith ─────────────────────────────────────────────────
  @override
  AppTypography copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? headlineLarge,
    TextStyle? headlineMedium,
    TextStyle? headlineSmall,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelMedium,
    TextStyle? labelSmall,
    TextStyle? button,
    TextStyle? caption,
  }) {
    return AppTypography(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
      button: button ?? this.button,
      caption: caption ?? this.caption,
    );
  }

  // ── lerp ─────────────────────────────────────────────────────
  @override
  AppTypography lerp(covariant ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      displayMedium: TextStyle.lerp(displayMedium, other.displayMedium, t)!,
      displaySmall: TextStyle.lerp(displaySmall, other.displaySmall, t)!,
      headlineLarge: TextStyle.lerp(headlineLarge, other.headlineLarge, t)!,
      headlineMedium: TextStyle.lerp(headlineMedium, other.headlineMedium, t)!,
      headlineSmall: TextStyle.lerp(headlineSmall, other.headlineSmall, t)!,
      titleLarge: TextStyle.lerp(titleLarge, other.titleLarge, t)!,
      titleMedium: TextStyle.lerp(titleMedium, other.titleMedium, t)!,
      titleSmall: TextStyle.lerp(titleSmall, other.titleSmall, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      labelLarge: TextStyle.lerp(labelLarge, other.labelLarge, t)!,
      labelMedium: TextStyle.lerp(labelMedium, other.labelMedium, t)!,
      labelSmall: TextStyle.lerp(labelSmall, other.labelSmall, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }
}