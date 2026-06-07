import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  // ── Primary Purple/Indigo ──
  final Color primary;
  final Color primary50;
  final Color primary100;
  final Color primary200;
  final Color primary300;
  final Color primary400;
  final Color primary500;
  final Color primary600;
  final Color primary800;
  final Color primary900;
  final Color primary950;

  // ── Secondary Rose/Pink ──
  final Color secondary;
  final Color secondary50;
  final Color secondary100;
  final Color secondary200;
  final Color secondary300;
  final Color secondary400;
  final Color secondary500;
  final Color secondary600;
  final Color secondary800;
  final Color secondary900;
  final Color secondary950;

  // ── Neutrals ──
  final Color white;
  final Color black;
  final Color background;
  final Color surfaceLight;
  final Color surfaceDark;

  // ── Text ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color text4;
  final Color text5;

  // ── Borders ──
  final Color border;
  final Color borderLight;
  final Color activeBorder;
  final Color inActiveBorder;

  // ── Components ──
  final Color card;
  final Color accent2;
  final Color accent3;

  // ── Grays ──
  final Color gray;
  final Color gray2;
  final Color gray4;

  // ── Browns (amber/warn tones) ──
  final Color brown;
  final Color brownLight;
  final Color brownExtraLight;

  // ── Status ──
  final Color activeStatus;
  final Color inActiveStatus;
  final Color error;
  final Color errorLight;
  final Color errorExtraLight;
  final Color errorDark;
  final Color success;
  final Color successLight;
  final Color successDark;
  final Color warning;
  final Color warningLight;
  final Color warningDark;

  const AppColors({
    required this.primary,
    required this.primary50,
    required this.primary100,
    required this.primary200,
    required this.primary300,
    required this.primary400,
    required this.primary500,
    required this.primary600,
    required this.primary800,
    required this.primary900,
    required this.primary950,
    required this.secondary,
    required this.secondary50,
    required this.secondary100,
    required this.secondary200,
    required this.secondary300,
    required this.secondary400,
    required this.secondary500,
    required this.secondary600,
    required this.secondary800,
    required this.secondary900,
    required this.secondary950,
    required this.white,
    required this.black,
    required this.background,
    required this.surfaceLight,
    required this.surfaceDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.text4,
    required this.text5,
    required this.border,
    required this.borderLight,
    required this.activeBorder,
    required this.inActiveBorder,
    required this.card,
    required this.accent2,
    required this.accent3,
    required this.gray,
    required this.gray2,
    required this.gray4,
    required this.brown,
    required this.brownLight,
    required this.brownExtraLight,
    required this.activeStatus,
    required this.inActiveStatus,
    required this.error,
    required this.errorLight,
    required this.errorExtraLight,
    required this.errorDark,
    required this.success,
    required this.successLight,
    required this.successDark,
    required this.warning,
    required this.warningLight,
    required this.warningDark,
  });

  // ── Dark Preset ──────────────────────────────────────────────
  static const dark = AppColors(
    // Primary — inverted scale (50 = darkest, 950 = lightest in dark mode)
    primary: Color(0xFF7669E2),
    primary50: Color(0xFF1A1650),
    primary100: Color(0xFF2D2580),
    primary200: Color(0xFF3D33A8),
    primary300: Color(0xFF4D40BE),
    primary400: Color(0xFF5E50D4),
    primary500: Color(0xFF7669E2),
    primary600: Color(0xFF9289E8),
    primary800: Color(0xFFC9C5F5),
    primary900: Color(0xFFE4E2FA),
    primary950: Color(0xFFF3F2FD),

    // Secondary — inverted scale
    secondary: Color(0xFFE8669E),
    secondary50: Color(0xFF4A0D2C),
    secondary100: Color(0xFF7A1A4A),
    secondary200: Color(0xFF9E2860),
    secondary300: Color(0xFFB83878),
    secondary400: Color(0xFFD44D88),
    secondary500: Color(0xFFE8669E),
    secondary600: Color(0xFFEF80B0),
    secondary800: Color(0xFFFFBDD8),
    secondary900: Color(0xFFFFE0EE),
    secondary950: Color(0xFFFFF0F6),

    white: Color(0xFFFFFFFF),
    black: Color(0xFF000000),

    // Dark backgrounds (slate-950 → slate-900 → slate-800)
    background: Color(0xFF0F172A), // slate-900
    surfaceLight: Color(0xFF1E293B), // slate-800
    surfaceDark: Color(0xFF334155), // slate-700
    // Text — light on dark
    textPrimary: Color(0xFFF8FAFC), // near-white
    textSecondary: Color(0xFFCBD5E1), // slate-300
    textTertiary: Color(0xFF94A3B8), // slate-400
    text4: Color(0xFF64748B), // slate-500
    text5: Color(0xFF475569), // slate-600
    // Borders
    border: Color(0xFF334155), // slate-700
    borderLight: Color(0xFF475569), // slate-600
    activeBorder: Color(0xFF7669E2), // primary
    inActiveBorder: Color(0xFF475569), // slate-600
    // Components
    card: Color(0xFF1E293B), // slate-800
    accent2: Color(0xFF9289E8), // primary-600 (lighter in dark)
    accent3: Color(0xFFEF80B0), // secondary-600
    // Grays
    gray: Color(0xFF64748B),
    gray2: Color(0xFF94A3B8),
    gray4: Color(0xFF334155),

    // Browns (amber tones)
    brown: Color(0xFFFBBF24),
    brownLight: Color(0xFFFEF3C7),
    brownExtraLight: Color(0xFFFEFCE8),

    // Status
    activeStatus: Color(0xFF10B981),
    inActiveStatus: Color(0xFF64748B),

    // Error
    error: Color(0xFFEF4444),
    errorLight: Color(0xFF7F1D1D),
    errorExtraLight: Color(0xFF991B1B),
    errorDark: Color(0xFFDC2626),

    // Success
    success: Color(0xFF10B981),
    successLight: Color(0xFF065F46),
    successDark: Color(0xFF059669),

    // Warning
    warning: Color(0xFFF59E0B),
    warningLight: Color(0xFF78350F),
    warningDark: Color(0xFFD97706),
  );

  static const light = AppColors(
    // Primary — normal scale (50 = lightest, 950 = darkest in light mode)
    primary: Color(0xFF7669E2),
    primary50: Color(0xFFF3F2FD),
    primary100: Color(0xFFE4E2FA),
    primary200: Color(0xFFC9C5F5),
    primary300: Color(0xFF9289E8),
    primary400: Color(0xFF7669E2),
    primary500: Color(0xFF5E50D4),
    primary600: Color(0xFF4D40BE),
    primary800: Color(0xFF2D2580),
    primary900: Color(0xFF1A1650),
    primary950: Color(0xFF0D0B28),

    // Secondary
    secondary: Color(0xFFE8669E),
    secondary50: Color(0xFFFFF0F6),
    secondary100: Color(0xFFFFE0EE),
    secondary200: Color(0xFFFFBDD8),
    secondary300: Color(0xFFEF80B0),
    secondary400: Color(0xFFE8669E),
    secondary500: Color(0xFFD44D88),
    secondary600: Color(0xFFB83878),
    secondary800: Color(0xFF7A1A4A),
    secondary900: Color(0xFF4A0D2C),
    secondary950: Color(0xFF2D0719),

    white: Color(0xFFFFFFFF),
    black: Color(0xFF000000),

    // Light backgrounds
    background: Color(0xFFF8FAFC), // slate-50
    surfaceLight: Color(0xFFFFFFFF), // pure white
    surfaceDark: Color(0xFFF1F5F9), // slate-100
    // Text — dark on light
    textPrimary: Color(0xFF0F172A), // slate-900
    textSecondary: Color(0xFF334155), // slate-700
    textTertiary: Color(0xFF64748B), // slate-500
    text4: Color(0xFF94A3B8), // slate-400
    text5: Color(0xFFCBD5E1), // slate-300
    // Borders
    border: Color(0xFFE2E8F0), // slate-200
    borderLight: Color(0xFFCBD5E1), // slate-300
    activeBorder: Color(0xFF7669E2),
    inActiveBorder: Color(0xFFCBD5E1),

    // Components
    card: Color(0xFFFFFFFF),
    accent2: Color(0xFF5E50D4),
    accent3: Color(0xFFD44D88),

    // Grays
    gray: Color(0xFF94A3B8),
    gray2: Color(0xFF64748B),
    gray4: Color(0xFFE2E8F0),

    // Browns
    brown: Color(0xFFD97706),
    brownLight: Color(0xFFFEF3C7),
    brownExtraLight: Color(0xFFFEFCE8),

    // Status
    activeStatus: Color(0xFF10B981),
    inActiveStatus: Color(0xFF94A3B8),

    // Error
    error: Color(0xFFEF4444),
    errorLight: Color(0xFFFEE2E2),
    errorExtraLight: Color(0xFFFEF2F2),
    errorDark: Color(0xFFDC2626),

    // Success
    success: Color(0xFF10B981),
    successLight: Color(0xFFD1FAE5),
    successDark: Color(0xFF059669),

    // Warning
    warning: Color(0xFFF59E0B),
    warningLight: Color(0xFFFEF3C7),
    warningDark: Color(0xFFD97706),
  );
  @override
  AppColors copyWith({
    Color? primary,
    Color? primary50,
    Color? primary100,
    Color? primary200,
    Color? primary300,
    Color? primary400,
    Color? primary500,
    Color? primary600,
    Color? primary800,
    Color? primary900,
    Color? primary950,
    Color? secondary,
    Color? secondary50,
    Color? secondary100,
    Color? secondary200,
    Color? secondary300,
    Color? secondary400,
    Color? secondary500,
    Color? secondary600,
    Color? secondary800,
    Color? secondary900,
    Color? secondary950,
    Color? white,
    Color? black,
    Color? background,
    Color? surfaceLight,
    Color? surfaceDark,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? text4,
    Color? text5,
    Color? border,
    Color? borderLight,
    Color? activeBorder,
    Color? inActiveBorder,
    Color? card,
    Color? accent2,
    Color? accent3,
    Color? gray,
    Color? gray2,
    Color? gray4,
    Color? brown,
    Color? brownLight,
    Color? brownExtraLight,
    Color? activeStatus,
    Color? inActiveStatus,
    Color? error,
    Color? errorLight,
    Color? errorExtraLight,
    Color? errorDark,
    Color? success,
    Color? successLight,
    Color? successDark,
    Color? warning,
    Color? warningLight,
    Color? warningDark,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primary50: primary50 ?? this.primary50,
      primary100: primary100 ?? this.primary100,
      primary200: primary200 ?? this.primary200,
      primary300: primary300 ?? this.primary300,
      primary400: primary400 ?? this.primary400,
      primary500: primary500 ?? this.primary500,
      primary600: primary600 ?? this.primary600,
      primary800: primary800 ?? this.primary800,
      primary900: primary900 ?? this.primary900,
      primary950: primary950 ?? this.primary950,
      secondary: secondary ?? this.secondary,
      secondary50: secondary50 ?? this.secondary50,
      secondary100: secondary100 ?? this.secondary100,
      secondary200: secondary200 ?? this.secondary200,
      secondary300: secondary300 ?? this.secondary300,
      secondary400: secondary400 ?? this.secondary400,
      secondary500: secondary500 ?? this.secondary500,
      secondary600: secondary600 ?? this.secondary600,
      secondary800: secondary800 ?? this.secondary800,
      secondary900: secondary900 ?? this.secondary900,
      secondary950: secondary950 ?? this.secondary950,
      white: white ?? this.white,
      black: black ?? this.black,
      background: background ?? this.background,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      surfaceDark: surfaceDark ?? this.surfaceDark,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      text4: text4 ?? this.text4,
      text5: text5 ?? this.text5,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      activeBorder: activeBorder ?? this.activeBorder,
      inActiveBorder: inActiveBorder ?? this.inActiveBorder,
      card: card ?? this.card,
      accent2: accent2 ?? this.accent2,
      accent3: accent3 ?? this.accent3,
      gray: gray ?? this.gray,
      gray2: gray2 ?? this.gray2,
      gray4: gray4 ?? this.gray4,
      brown: brown ?? this.brown,
      brownLight: brownLight ?? this.brownLight,
      brownExtraLight: brownExtraLight ?? this.brownExtraLight,
      activeStatus: activeStatus ?? this.activeStatus,
      inActiveStatus: inActiveStatus ?? this.inActiveStatus,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      errorExtraLight: errorExtraLight ?? this.errorExtraLight,
      errorDark: errorDark ?? this.errorDark,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      successDark: successDark ?? this.successDark,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      warningDark: warningDark ?? this.warningDark,
    );
  }

  // ── lerp ─────────────────────────────────────────────────────
  @override
  AppColors lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primary50: Color.lerp(primary50, other.primary50, t)!,
      primary100: Color.lerp(primary100, other.primary100, t)!,
      primary200: Color.lerp(primary200, other.primary200, t)!,
      primary300: Color.lerp(primary300, other.primary300, t)!,
      primary400: Color.lerp(primary400, other.primary400, t)!,
      primary500: Color.lerp(primary500, other.primary500, t)!,
      primary600: Color.lerp(primary600, other.primary600, t)!,
      primary800: Color.lerp(primary800, other.primary800, t)!,
      primary900: Color.lerp(primary900, other.primary900, t)!,
      primary950: Color.lerp(primary950, other.primary950, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondary50: Color.lerp(secondary50, other.secondary50, t)!,
      secondary100: Color.lerp(secondary100, other.secondary100, t)!,
      secondary200: Color.lerp(secondary200, other.secondary200, t)!,
      secondary300: Color.lerp(secondary300, other.secondary300, t)!,
      secondary400: Color.lerp(secondary400, other.secondary400, t)!,
      secondary500: Color.lerp(secondary500, other.secondary500, t)!,
      secondary600: Color.lerp(secondary600, other.secondary600, t)!,
      secondary800: Color.lerp(secondary800, other.secondary800, t)!,
      secondary900: Color.lerp(secondary900, other.secondary900, t)!,
      secondary950: Color.lerp(secondary950, other.secondary950, t)!,
      white: Color.lerp(white, other.white, t)!,
      black: Color.lerp(black, other.black, t)!,
      background: Color.lerp(background, other.background, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      surfaceDark: Color.lerp(surfaceDark, other.surfaceDark, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      text4: Color.lerp(text4, other.text4, t)!,
      text5: Color.lerp(text5, other.text5, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      activeBorder: Color.lerp(activeBorder, other.activeBorder, t)!,
      inActiveBorder: Color.lerp(inActiveBorder, other.inActiveBorder, t)!,
      card: Color.lerp(card, other.card, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      accent3: Color.lerp(accent3, other.accent3, t)!,
      gray: Color.lerp(gray, other.gray, t)!,
      gray2: Color.lerp(gray2, other.gray2, t)!,
      gray4: Color.lerp(gray4, other.gray4, t)!,
      brown: Color.lerp(brown, other.brown, t)!,
      brownLight: Color.lerp(brownLight, other.brownLight, t)!,
      brownExtraLight: Color.lerp(brownExtraLight, other.brownExtraLight, t)!,
      activeStatus: Color.lerp(activeStatus, other.activeStatus, t)!,
      inActiveStatus: Color.lerp(inActiveStatus, other.inActiveStatus, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      errorExtraLight: Color.lerp(errorExtraLight, other.errorExtraLight, t)!,
      errorDark: Color.lerp(errorDark, other.errorDark, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      successDark: Color.lerp(successDark, other.successDark, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      warningDark: Color.lerp(warningDark, other.warningDark, t)!,
    );
  }
}
