// lib/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Light colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFEFF6FF);

  // Light theme colors
  static const Color _lightBackground = Color(0xFFF3F4F6);
  static const Color _lightSurface = Colors.white;
  static const Color _lightTextPrimary = Color(0xFF111827);
  static const Color _lightTextSecondary = Color(0xFF6B7280);
  static const Color _lightTextMuted = Color(0xFF9CA3AF);
  static const Color _lightBorder = Color(0xFFE5E7EB);

  // Dark theme colors
  static const Color _darkBackground = Color(0xFF0F172A);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkTextPrimary = Color(0xFFF1F5F9);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);
  static const Color _darkTextMuted = Color(0xFF64748B);
  static const Color _darkBorder = Color(0xFF334155);

  // Semantic colors (same for both)
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color purple = Color(0xFF7C3AED);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = isDark ? _darkBackground : _lightBackground;
    final surface = isDark ? _darkSurface : _lightSurface;
    final textPrimary = isDark ? _darkTextPrimary : _lightTextPrimary;
    final border = isDark ? _darkBorder : _lightBorder;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'sans-serif',
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }

  // Helper to get colors based on context
  static Color background(BuildContext context) =>
      _resolve(context, _lightBackground, _darkBackground);
  static Color surface(BuildContext context) =>
      _resolve(context, _lightSurface, _darkSurface);
  static Color textPrimary(BuildContext context) =>
      _resolve(context, _lightTextPrimary, _darkTextPrimary);
  static Color textSecondary(BuildContext context) =>
      _resolve(context, _lightTextSecondary, _darkTextSecondary);
  static Color textMuted(BuildContext context) =>
      _resolve(context, _lightTextMuted, _darkTextMuted);
  static Color border(BuildContext context) =>
      _resolve(context, _lightBorder, _darkBorder);

  static Color _resolve(BuildContext context, Color light, Color dark) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

// Reusable card widget
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
    );
  }
}

Color courseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}