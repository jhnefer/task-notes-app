import 'package:app/themes/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.background,
    onSurface: AppColors.onPrimary,
    error: AppColors.destructive,
  );

  static ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.onSidebarPrimary,
    surface: AppColors.darkBackground,
    onSurface: AppColors.darkOnSurface,
    error: AppColors.destructive,
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: lightColorScheme,
    primaryColor: AppColors.primary,
    primaryTextTheme: textTheme,
    textTheme: textTheme,
    appBarTheme: appBarThemeData,
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: darkColorScheme,
    primaryColor: AppColors.primary,
    primaryTextTheme: darkTextTheme,
    textTheme: darkTextTheme,
    appBarTheme: darkAppBarThemeData,
    dividerTheme: const DividerThemeData(
      color: AppColors.darkCardBorder,
      thickness: 1,
    ),
  );

  static AppBarThemeData appBarThemeData = const AppBarThemeData(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.onPrimary,
    iconTheme: IconThemeData(color: AppColors.onPrimary),
  );

  static AppBarThemeData darkAppBarThemeData = const AppBarThemeData(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.darkOnSurface,
    iconTheme: IconThemeData(color: AppColors.darkOnSurface),
  );

  static TextTheme textTheme = const TextTheme(
    headlineSmall: TextStyle(fontFamily: 'Playfair Display', fontWeight: .bold),
    headlineMedium: TextStyle(fontFamily: 'Playfair Display'),
    headlineLarge: TextStyle(fontFamily: 'Playfair Display'),

    displaySmall: TextStyle(
      fontFamily: 'Playfair Display',
      color: AppColors.secondary,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Playfair Display',
      color: AppColors.secondary,
    ),
    displayLarge: TextStyle(
      fontFamily: 'Playfair Display',
      color: AppColors.secondary,
      fontWeight: .bold,
    ),

    titleSmall: TextStyle(fontFamily: 'Playfair Display', fontWeight: .bold),
    titleMedium: TextStyle(fontFamily: 'Playfair Display', fontWeight: .bold),
    titleLarge: TextStyle(fontFamily: 'Playfair Display', fontWeight: .bold),

    bodySmall: TextStyle(fontFamily: 'Lora'),
    bodyMedium: TextStyle(fontFamily: 'Lora'),
    bodyLarge: TextStyle(fontFamily: 'Lora'),

    labelSmall: TextStyle(fontFamily: 'Caveat'),
    labelMedium: TextStyle(fontFamily: 'Caveat'),
    labelLarge: TextStyle(fontFamily: 'Caveat'),
  );

  static TextTheme darkTextTheme = textTheme.apply(
    bodyColor: AppColors.darkOnSurface,
    displayColor: AppColors.darkOnSurface,
  );
}
