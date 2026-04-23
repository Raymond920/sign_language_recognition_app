import 'package:flutter/material.dart';

class AppTheme {
  static const Color _darkMainBackground = Color(0xFF0F1117);
  static const Color _darkCardBackground = Color(0xFF1A1D29);
  static const Color _darkMutedBackground = Color(0xFF2A2D3A);
  static const Color _darkTextPrimary = Color(0xFFF5F5F7);
  static const Color _darkTextMuted = Color(0xFF9CA3AF);

  static const Color _primary = Color(0xFF6366F1);
  static const Color _secondary = Color(0xFF8B5CF6);
  static const Color _accent = Color(0xFF06B6D4);

  static const Color _success = Color(0xFF10B981);
  static const Color _error = Color(0xFFEF4444);

  static const Color _border = Color(0xFF2A2D3A);
  static const Color _switchBackground = Color(0xFF4B5563);
  static const Color _focusRing = Color(0xFF6B7280);
  static const Color _cameraBackground = Color(0xFF030712);

  static ThemeData get lightTheme {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: _primary,
      onPrimary: Colors.white,
      secondary: _secondary,
      onSecondary: Colors.white,
      tertiary: _accent,
      onTertiary: Colors.white,
      error: _error,
      onError: Colors.white,
      outline: const Color(0xFFE0E0E0),
      outlineVariant: const Color(0xFFEAECEF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: Colors.white,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _focusRing),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (states) => Colors.white,
        ),
      ),
      extensions: const [
        AppUiColors.light(),
      ],
    );
  }

  static ThemeData get darkTheme {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _primary,
      onPrimary: Colors.white,
      secondary: _secondary,
      onSecondary: Colors.white,
      tertiary: _accent,
      onTertiary: Colors.white,
      error: _error,
      onError: Colors.white,
      surface: _darkCardBackground,
      onSurface: _darkTextPrimary,
      onSurfaceVariant: _darkTextMuted,
      surfaceContainerLow: _darkCardBackground,
      surfaceContainer: _darkCardBackground,
      surfaceContainerHigh: _darkMutedBackground,
      surfaceContainerHighest: _darkMutedBackground,
      outline: _border,
      outlineVariant: _border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: _darkMainBackground,
      canvasColor: _darkMainBackground,
      cardColor: _darkCardBackground,
      dividerColor: _border,
      textTheme: ThemeData.dark(useMaterial3: true).textTheme.apply(
            bodyColor: _darkTextPrimary,
            displayColor: _darkTextPrimary,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkCardBackground,
        foregroundColor: _darkTextPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkMutedBackground,
        hintStyle: const TextStyle(color: _darkTextMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _focusRing),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return _primary;
          }
          return _switchBackground;
        }),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          return Colors.white;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return _primary;
          }
          return _border;
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
        ),
      ),
      extensions: const [
        AppUiColors.dark(),
      ],
    );
  }

  static Color get successColor => _success;
  static Color get destructiveColor => _error;
  static Color get cameraBackground => _cameraBackground;
}

@immutable
class AppUiColors extends ThemeExtension<AppUiColors> {
  const AppUiColors({
    required this.sidebarBackground,
    required this.sidebarForeground,
    required this.sidebarPrimary,
    required this.sidebarAccent,
    required this.sidebarBorder,
    required this.achievementYellowBackground,
    required this.achievementYellowBorder,
    required this.achievementYellowText,
    required this.successBackground,
    required this.successBorder,
    required this.successText,
    required this.cameraBackground,
  });

  const AppUiColors.dark()
      : sidebarBackground = const Color(0xFF1A1D29),
        sidebarForeground = const Color(0xFFF5F5F7),
        sidebarPrimary = const Color(0xFF6366F1),
        sidebarAccent = const Color(0xFF2A2D3A),
        sidebarBorder = const Color(0xFF2A2D3A),
        achievementYellowBackground = const Color(0x33A16207),
        achievementYellowBorder = const Color(0xFFA16207),
        achievementYellowText = const Color(0xFFFACC15),
        successBackground = const Color(0x3315803D),
        successBorder = const Color(0xFF15803D),
        successText = const Color(0xFF86EFAC),
        cameraBackground = const Color(0xFF030712);

  const AppUiColors.light()
      : sidebarBackground = Colors.white,
        sidebarForeground = const Color(0xFF111827),
        sidebarPrimary = const Color(0xFF6366F1),
        sidebarAccent = const Color(0xFFF3F4F6),
        sidebarBorder = const Color(0xFFE5E7EB),
        achievementYellowBackground = const Color(0x1AFACC15),
        achievementYellowBorder = const Color(0xFFD97706),
        achievementYellowText = const Color(0xFFB45309),
        successBackground = const Color(0x1A10B981),
        successBorder = const Color(0xFF059669),
        successText = const Color(0xFF047857),
        cameraBackground = const Color(0xFF030712);

  final Color sidebarBackground;
  final Color sidebarForeground;
  final Color sidebarPrimary;
  final Color sidebarAccent;
  final Color sidebarBorder;
  final Color achievementYellowBackground;
  final Color achievementYellowBorder;
  final Color achievementYellowText;
  final Color successBackground;
  final Color successBorder;
  final Color successText;
  final Color cameraBackground;

  @override
  AppUiColors copyWith({
    Color? sidebarBackground,
    Color? sidebarForeground,
    Color? sidebarPrimary,
    Color? sidebarAccent,
    Color? sidebarBorder,
    Color? achievementYellowBackground,
    Color? achievementYellowBorder,
    Color? achievementYellowText,
    Color? successBackground,
    Color? successBorder,
    Color? successText,
    Color? cameraBackground,
  }) {
    return AppUiColors(
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarForeground: sidebarForeground ?? this.sidebarForeground,
      sidebarPrimary: sidebarPrimary ?? this.sidebarPrimary,
      sidebarAccent: sidebarAccent ?? this.sidebarAccent,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      achievementYellowBackground:
          achievementYellowBackground ?? this.achievementYellowBackground,
      achievementYellowBorder:
          achievementYellowBorder ?? this.achievementYellowBorder,
      achievementYellowText: achievementYellowText ?? this.achievementYellowText,
      successBackground: successBackground ?? this.successBackground,
      successBorder: successBorder ?? this.successBorder,
      successText: successText ?? this.successText,
      cameraBackground: cameraBackground ?? this.cameraBackground,
    );
  }

  @override
  AppUiColors lerp(ThemeExtension<AppUiColors>? other, double t) {
    if (other is! AppUiColors) {
      return this;
    }

    return AppUiColors(
      sidebarBackground:
          Color.lerp(sidebarBackground, other.sidebarBackground, t) ?? sidebarBackground,
      sidebarForeground:
          Color.lerp(sidebarForeground, other.sidebarForeground, t) ?? sidebarForeground,
      sidebarPrimary: Color.lerp(sidebarPrimary, other.sidebarPrimary, t) ?? sidebarPrimary,
      sidebarAccent: Color.lerp(sidebarAccent, other.sidebarAccent, t) ?? sidebarAccent,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t) ?? sidebarBorder,
      achievementYellowBackground: Color.lerp(
            achievementYellowBackground,
            other.achievementYellowBackground,
            t,
          ) ??
          achievementYellowBackground,
      achievementYellowBorder:
          Color.lerp(achievementYellowBorder, other.achievementYellowBorder, t) ??
              achievementYellowBorder,
      achievementYellowText:
          Color.lerp(achievementYellowText, other.achievementYellowText, t) ??
              achievementYellowText,
      successBackground:
          Color.lerp(successBackground, other.successBackground, t) ?? successBackground,
      successBorder: Color.lerp(successBorder, other.successBorder, t) ?? successBorder,
      successText: Color.lerp(successText, other.successText, t) ?? successText,
      cameraBackground:
          Color.lerp(cameraBackground, other.cameraBackground, t) ?? cameraBackground,
    );
  }
}