import 'package:flutter/material.dart';

@immutable
class AppGradients extends ThemeExtension<AppGradients> {
  // ── Core ──
  final LinearGradient primary;
  final LinearGradient primaryReverse;
  final LinearGradient primaryVertical;
  final LinearGradient secondary;
  final LinearGradient secondaryReverse;

  // ── Glass / Brand blend ──
  final LinearGradient glass;
  final LinearGradient glassReverse;
  final LinearGradient glassVertical;

  // ── Signature combos ──
  final LinearGradient purpleRose;
  final LinearGradient rosePurple;
  final LinearGradient purpleIndigo;
  final LinearGradient roseDeep;

  // ── Backgrounds ──
  final LinearGradient backgroundDark;
  final LinearGradient backgroundLight;
  final LinearGradient surface;

  // ── Overlays ──
  final LinearGradient glassOverlay;
  final LinearGradient glassOverlaySubtle;
  final LinearGradient overlayBottom;
  final LinearGradient overlayTop;

  // ── Utility ──
  final LinearGradient shimmer;
  final LinearGradient welcomeBox;

  // ── Password strength ──
  final LinearGradient passwordWeak;
  final LinearGradient passwordMedium;
  final LinearGradient passwordStrong;

  const AppGradients({
    required this.primary,
    required this.primaryReverse,
    required this.primaryVertical,
    required this.secondary,
    required this.secondaryReverse,
    required this.glass,
    required this.glassReverse,
    required this.glassVertical,
    required this.purpleRose,
    required this.rosePurple,
    required this.purpleIndigo,
    required this.roseDeep,
    required this.backgroundDark,
    required this.backgroundLight,
    required this.surface,
    required this.glassOverlay,
    required this.glassOverlaySubtle,
    required this.overlayBottom,
    required this.overlayTop,
    required this.shimmer,
    required this.welcomeBox,
    required this.passwordWeak,
    required this.passwordMedium,
    required this.passwordStrong,
  });

  // ── Dark Preset ──────────────────────────────────────────────
  static final dark = AppGradients(
    // Primary — lighter → base (dark mode: start lighter)
    primary: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF7669E2), Color(0xFF9289E8)],
    ),
    primaryReverse: const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFF7669E2), Color(0xFF9289E8)],
    ),
    primaryVertical: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF7669E2), Color(0xFF9289E8)],
    ),

    // Secondary
    secondary: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFE8669E), Color(0xFFEF80B0)],
    ),
    secondaryReverse: const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFFE8669E), Color(0xFFEF80B0)],
    ),

    // Glass — purple → rose diagonal blend
    glass: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF9289E8), Color(0xFFEF80B0)],
    ),
    glassReverse: const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFF9289E8), Color(0xFFEF80B0)],
    ),
    glassVertical: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF9289E8), Color(0xFFEF80B0)],
    ),

    // Signature combos
    purpleRose: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7669E2), Color(0xFFE8669E)],
    ),
    rosePurple: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE8669E), Color(0xFF7669E2)],
    ),
    purpleIndigo: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9289E8), Color(0xFF7669E2)],
    ),
    roseDeep: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEF80B0), Color(0xFFE8669E)],
    ),

    // Backgrounds
    backgroundDark: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF020617), Color(0xFF0F172A)], // slate-950 → slate-900
    ),
    backgroundLight: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // slate-900 → slate-800
    ),
    surface: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1E293B), Color(0xFF334155)], // slate-800 → slate-700
    ),

    // Overlays
    glassOverlay: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF7669E2).withValues(alpha: 0.15),
        const Color(0xFFE8669E).withValues(alpha: 0.15),
      ],
    ),
    glassOverlaySubtle: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF7669E2).withValues(alpha: 0.08),
        const Color(0xFFE8669E).withValues(alpha: 0.08),
      ],
    ),
    overlayBottom: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        const Color(0xFF000000).withValues(alpha: 0.8),
      ],
    ),
    overlayTop: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Colors.transparent,
        const Color(0xFF000000).withValues(alpha: 0.8),
      ],
    ),

    // Shimmer — subtle white flash for skeleton loaders
    shimmer: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.08),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ),

    // Welcome box tint
    welcomeBox: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF7669E2).withValues(alpha: 0.10),
        const Color(0xFFE8669E).withValues(alpha: 0.10),
      ],
    ),

    // Password strength indicators
    passwordWeak: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    ),
    passwordMedium: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
    passwordStrong: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF10B981), Color(0xFF059669)],
    ),
  );

  static final light = AppGradients(
    primary: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF7669E2), Color(0xFF5E50D4)],
    ),
    primaryReverse: const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFF7669E2), Color(0xFF5E50D4)],
    ),
    primaryVertical: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF7669E2), Color(0xFF5E50D4)],
    ),
    secondary: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFE8669E), Color(0xFFD44D88)],
    ),
    secondaryReverse: const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFFE8669E), Color(0xFFD44D88)],
    ),
    glass: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF5E50D4), Color(0xFFD44D88)],
    ),
    glassReverse: const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFF5E50D4), Color(0xFFD44D88)],
    ),
    glassVertical: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF5E50D4), Color(0xFFD44D88)],
    ),
    purpleRose: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7669E2), Color(0xFFE8669E)],
    ),
    rosePurple: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE8669E), Color(0xFF7669E2)],
    ),
    purpleIndigo: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF5E50D4), Color(0xFF7669E2)],
    ),
    roseDeep: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD44D88), Color(0xFFE8669E)],
    ),
    backgroundDark: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
    ),
    backgroundLight: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    ),
    surface: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
    ),
    glassOverlay: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF7669E2).withValues(alpha: 0.08),
        const Color(0xFFE8669E).withValues(alpha: 0.08),
      ],
    ),
    glassOverlaySubtle: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF7669E2).withValues(alpha: 0.04),
        const Color(0xFFE8669E).withValues(alpha: 0.04),
      ],
    ),
    overlayBottom: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, const Color(0xFF000000).withValues(alpha: 0.4)],
    ),
    overlayTop: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Colors.transparent, const Color(0xFF000000).withValues(alpha: 0.4)],
    ),
    shimmer: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.04),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ),
    welcomeBox: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF7669E2).withValues(alpha: 0.06),
        const Color(0xFFE8669E).withValues(alpha: 0.06),
      ],
    ),
    passwordWeak: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    ),
    passwordMedium: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
    passwordStrong: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF10B981), Color(0xFF059669)],
    ),
  );
  @override
  AppGradients copyWith({
    LinearGradient? primary,
    LinearGradient? primaryReverse,
    LinearGradient? primaryVertical,
    LinearGradient? secondary,
    LinearGradient? secondaryReverse,
    LinearGradient? glass,
    LinearGradient? glassReverse,
    LinearGradient? glassVertical,
    LinearGradient? purpleRose,
    LinearGradient? rosePurple,
    LinearGradient? purpleIndigo,
    LinearGradient? roseDeep,
    LinearGradient? backgroundDark,
    LinearGradient? backgroundLight,
    LinearGradient? surface,
    LinearGradient? glassOverlay,
    LinearGradient? glassOverlaySubtle,
    LinearGradient? overlayBottom,
    LinearGradient? overlayTop,
    LinearGradient? shimmer,
    LinearGradient? welcomeBox,
    LinearGradient? passwordWeak,
    LinearGradient? passwordMedium,
    LinearGradient? passwordStrong,
  }) {
    return AppGradients(
      primary: primary ?? this.primary,
      primaryReverse: primaryReverse ?? this.primaryReverse,
      primaryVertical: primaryVertical ?? this.primaryVertical,
      secondary: secondary ?? this.secondary,
      secondaryReverse: secondaryReverse ?? this.secondaryReverse,
      glass: glass ?? this.glass,
      glassReverse: glassReverse ?? this.glassReverse,
      glassVertical: glassVertical ?? this.glassVertical,
      purpleRose: purpleRose ?? this.purpleRose,
      rosePurple: rosePurple ?? this.rosePurple,
      purpleIndigo: purpleIndigo ?? this.purpleIndigo,
      roseDeep: roseDeep ?? this.roseDeep,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      surface: surface ?? this.surface,
      glassOverlay: glassOverlay ?? this.glassOverlay,
      glassOverlaySubtle: glassOverlaySubtle ?? this.glassOverlaySubtle,
      overlayBottom: overlayBottom ?? this.overlayBottom,
      overlayTop: overlayTop ?? this.overlayTop,
      shimmer: shimmer ?? this.shimmer,
      welcomeBox: welcomeBox ?? this.welcomeBox,
      passwordWeak: passwordWeak ?? this.passwordWeak,
      passwordMedium: passwordMedium ?? this.passwordMedium,
      passwordStrong: passwordStrong ?? this.passwordStrong,
    );
  }

  // ── lerp ─────────────────────────────────────────────────────
  @override
  AppGradients lerp(covariant ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(
      primary: LinearGradient.lerp(primary, other.primary, t)!,
      primaryReverse: LinearGradient.lerp(
        primaryReverse,
        other.primaryReverse,
        t,
      )!,
      primaryVertical: LinearGradient.lerp(
        primaryVertical,
        other.primaryVertical,
        t,
      )!,
      secondary: LinearGradient.lerp(secondary, other.secondary, t)!,
      secondaryReverse: LinearGradient.lerp(
        secondaryReverse,
        other.secondaryReverse,
        t,
      )!,
      glass: LinearGradient.lerp(glass, other.glass, t)!,
      glassReverse: LinearGradient.lerp(glassReverse, other.glassReverse, t)!,
      glassVertical: LinearGradient.lerp(
        glassVertical,
        other.glassVertical,
        t,
      )!,
      purpleRose: LinearGradient.lerp(purpleRose, other.purpleRose, t)!,
      rosePurple: LinearGradient.lerp(rosePurple, other.rosePurple, t)!,
      purpleIndigo: LinearGradient.lerp(purpleIndigo, other.purpleIndigo, t)!,
      roseDeep: LinearGradient.lerp(roseDeep, other.roseDeep, t)!,
      backgroundDark: LinearGradient.lerp(
        backgroundDark,
        other.backgroundDark,
        t,
      )!,
      backgroundLight: LinearGradient.lerp(
        backgroundLight,
        other.backgroundLight,
        t,
      )!,
      surface: LinearGradient.lerp(surface, other.surface, t)!,
      glassOverlay: LinearGradient.lerp(glassOverlay, other.glassOverlay, t)!,
      glassOverlaySubtle: LinearGradient.lerp(
        glassOverlaySubtle,
        other.glassOverlaySubtle,
        t,
      )!,
      overlayBottom: LinearGradient.lerp(
        overlayBottom,
        other.overlayBottom,
        t,
      )!,
      overlayTop: LinearGradient.lerp(overlayTop, other.overlayTop, t)!,
      shimmer: LinearGradient.lerp(shimmer, other.shimmer, t)!,
      welcomeBox: LinearGradient.lerp(welcomeBox, other.welcomeBox, t)!,
      passwordWeak: LinearGradient.lerp(passwordWeak, other.passwordWeak, t)!,
      passwordMedium: LinearGradient.lerp(
        passwordMedium,
        other.passwordMedium,
        t,
      )!,
      passwordStrong: LinearGradient.lerp(
        passwordStrong,
        other.passwordStrong,
        t,
      )!,
    );
  }
}
