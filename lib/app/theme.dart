// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';

/// Leventa brand tokens (docs/DESIGN_SYSTEM.md). Widgets read colors from
/// here via `context.c`, never raw hex.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.background,
    required this.surface,
    required this.text,
    required this.textMuted,
    required this.border,
  });

  final Color primary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color background;
  final Color surface;
  final Color text;
  final Color textMuted;
  final Color border;

  static const leventa = AppColors(
    primary: Color(0xFF2563EB),
    secondary: Color(0xFF22C55E),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFDC2626),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF0F172A),
    textMuted: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => this;
}

extension ThemeX on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>()!;
  TextTheme get t => Theme.of(this).textTheme;
}

/// 8pt spacing rhythm.
class Gap {
  const Gap._();
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
}

class Radii {
  const Radii._();
  static const control = 12.0;
  static const card = 16.0;
}

ThemeData buildTheme() {
  const c = AppColors.leventa;
  final scheme = ColorScheme.fromSeed(
    seedColor: c.primary,
    primary: c.primary,
    secondary: c.secondary,
    error: c.danger,
    surface: c.surface,
    onSurface: c.text,
    outline: c.border,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: c.background,
    extensions: const [c],
  );
  final text = base.textTheme.apply(bodyColor: c.text, displayColor: c.text);
  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.control),
  );
  // D-pad / keyboard focus (TV remotes, desktop): Flutter shows these only in
  // that input mode, so touch users never see the ring.
  final focusRing = WidgetStateProperty.resolveWith<BorderSide?>(
    (s) => s.contains(WidgetState.focused)
        ? BorderSide(color: c.text, width: 3)
        : null,
  );
  return base.copyWith(
    focusColor: c.primary.withValues(alpha: 0.2),
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.45),
      bodySmall: text.bodySmall?.copyWith(color: c.textMuted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: c.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.border, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: c.border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: controlShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ).copyWith(side: focusRing),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: controlShape,
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.focused)
                  ? BorderSide(color: c.text, width: 3)
                  : BorderSide(color: c.border),
            ),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 44),
      ).copyWith(side: focusRing),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom().copyWith(side: focusRing),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      side: BorderSide(color: c.border),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.primary.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.primary.withValues(alpha: 0.12),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
