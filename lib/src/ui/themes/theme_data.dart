import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Theme data for SmoothChucker
class SmoothChuckerThemeData {
  /// Get the light theme for SmoothChucker
  static ThemeData getLightTheme([Color? primaryColor, Color? secondaryColor]) {
    final ColorScheme colorScheme = _getMaterialYouLightColorScheme(
      primaryColor ?? Colors.blue,
      secondaryColor ?? Colors.teal,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.7),
        indicatorColor: colorScheme.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        deleteIconColor: colorScheme.onSurface.withOpacity(0.7),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide(color: colorScheme.outline),
      ),
    );
  }

  /// Get the dark theme for SmoothChucker
  static ThemeData getDarkTheme([Color? primaryColor, Color? secondaryColor]) {
    final ColorScheme colorScheme = _getMaterialYouDarkColorScheme(
      primaryColor ?? Colors.blue,
      secondaryColor ?? Colors.teal,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.7),
        indicatorColor: colorScheme.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        deleteIconColor: colorScheme.onSurface.withOpacity(0.7),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide(color: colorScheme.outline),
      ),
    );
  }

  /// Get a Material You light color scheme based on a seed color
  static ColorScheme _getMaterialYouLightColorScheme(
      Color primaryColor, Color secondaryColor) {
    final CorePalette palette = CorePalette.of(primaryColor.value);
    final CorePalette secondaryPalette = CorePalette.of(secondaryColor.value);

    return ColorScheme(
      brightness: Brightness.light,
      primary: Color(palette.primary.get(40)),
      onPrimary: Color(palette.primary.get(100)),
      primaryContainer: Color(palette.primary.get(90)),
      onPrimaryContainer: Color(palette.primary.get(10)),
      secondary: Color(secondaryPalette.secondary.get(40)),
      onSecondary: Color(secondaryPalette.secondary.get(100)),
      secondaryContainer: Color(secondaryPalette.secondary.get(90)),
      onSecondaryContainer: Color(secondaryPalette.secondary.get(10)),
      tertiary: Color(palette.tertiary.get(40)),
      onTertiary: Color(palette.tertiary.get(100)),
      tertiaryContainer: Color(palette.tertiary.get(90)),
      onTertiaryContainer: Color(palette.tertiary.get(10)),
      error: Color(palette.error.get(40)),
      onError: Color(palette.error.get(100)),
      errorContainer: Color(palette.error.get(90)),
      onErrorContainer: Color(palette.error.get(10)),
      surface: Color(palette.neutral.get(99)),
      onSurface: Color(palette.neutral.get(10)),
      surfaceContainerHighest: Color(palette.neutralVariant.get(90)),
      onSurfaceVariant: Color(palette.neutralVariant.get(30)),
      outline: Color(palette.neutralVariant.get(50)),
      outlineVariant: Color(palette.neutralVariant.get(80)),
      shadow: Color(palette.neutral.get(0)),
      scrim: Color(palette.neutral.get(0)),
      inverseSurface: Color(palette.neutral.get(20)),
      onInverseSurface: Color(palette.neutral.get(95)),
      inversePrimary: Color(palette.primary.get(80)),
      surfaceTint: Color(palette.primary.get(40)),
    );
  }

  /// Get a Material You dark color scheme based on a seed color
  static ColorScheme _getMaterialYouDarkColorScheme(
      Color primaryColor, Color secondaryColor) {
    final CorePalette palette = CorePalette.of(primaryColor.value);
    final CorePalette secondaryPalette = CorePalette.of(secondaryColor.value);

    return ColorScheme(
      brightness: Brightness.dark,
      primary: Color(palette.primary.get(80)),
      onPrimary: Color(palette.primary.get(20)),
      primaryContainer: Color(palette.primary.get(30)),
      onPrimaryContainer: Color(palette.primary.get(90)),
      secondary: Color(secondaryPalette.secondary.get(80)),
      onSecondary: Color(secondaryPalette.secondary.get(20)),
      secondaryContainer: Color(secondaryPalette.secondary.get(30)),
      onSecondaryContainer: Color(secondaryPalette.secondary.get(90)),
      tertiary: Color(palette.tertiary.get(80)),
      onTertiary: Color(palette.tertiary.get(20)),
      tertiaryContainer: Color(palette.tertiary.get(30)),
      onTertiaryContainer: Color(palette.tertiary.get(90)),
      error: Color(palette.error.get(80)),
      onError: Color(palette.error.get(20)),
      errorContainer: Color(palette.error.get(30)),
      onErrorContainer: Color(palette.error.get(90)),
      surface: Color(palette.neutral.get(10)),
      onSurface: Color(palette.neutral.get(90)),
      surfaceContainerHighest: Color(palette.neutralVariant.get(30)),
      onSurfaceVariant: Color(palette.neutralVariant.get(80)),
      outline: Color(palette.neutralVariant.get(60)),
      outlineVariant: Color(palette.neutralVariant.get(30)),
      shadow: Color(palette.neutral.get(0)),
      scrim: Color(palette.neutral.get(0)),
      inverseSurface: Color(palette.neutral.get(90)),
      onInverseSurface: Color(palette.neutral.get(20)),
      inversePrimary: Color(palette.primary.get(40)),
      surfaceTint: Color(palette.primary.get(80)),
    );
  }
}
