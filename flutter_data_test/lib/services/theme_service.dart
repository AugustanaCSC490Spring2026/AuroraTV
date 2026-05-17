import 'package:flutter/material.dart';

import '../constants/colors.dart';

ThemeData buildAuroraTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: auroraInk,
    brightness: Brightness.light,
    primary: auroraYellow,
    secondary: auroraInk,
    tertiary: auroraBlue,
    surface: auroraCream,
    error: auroraInk,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: auroraCream,
    fontFamily: 'Arial',
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: auroraInk,
        fontSize: 44,
        fontWeight: FontWeight.w900,
        height: 0.98,
        letterSpacing: 0,
        shadows: [
          Shadow(color: auroraWhite, offset: Offset(2, 2)),
          Shadow(color: auroraYellow, offset: Offset(5, 5)),
        ],
      ),
      headlineMedium: TextStyle(
        color: auroraInk,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        height: 1.05,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: auroraInk,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        color: auroraInk,
        fontSize: 16,
        height: 1.35,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        color: auroraInk,
        fontSize: 14,
        height: 1.35,
        letterSpacing: 0,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: auroraCream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: auroraInk),
      titleTextStyle: TextStyle(
        color: auroraInk,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: auroraWhite,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: auroraInk),
      labelStyle: TextStyle(
        color: auroraInk,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      prefixIconColor: auroraInk,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: auroraInk, width: 3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: auroraInk, width: 3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: auroraInk, width: 4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: auroraInk, width: 3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: auroraInk, width: 4),
      ),
    ),
    dividerTheme: const DividerThemeData(color: auroraInk, thickness: 3),
    cardTheme: CardThemeData(
      color: auroraCream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: auroraInk, width: 3),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: auroraYellow,
        foregroundColor: auroraWhite,
        disabledBackgroundColor: auroraGreen,
        disabledForegroundColor: auroraCream,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        shape: const RoundedRectangleBorder(),
        side: const BorderSide(color: auroraInk, width: 3),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: auroraYellow,
        foregroundColor: auroraWhite,
        disabledBackgroundColor: auroraGreen,
        disabledForegroundColor: auroraCream,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        shape: const RoundedRectangleBorder(),
        side: const BorderSide(color: auroraInk, width: 3),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: auroraInk,
        backgroundColor: auroraGreen,
        side: const BorderSide(color: auroraInk, width: 3),
        shape: const RoundedRectangleBorder(),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: auroraInk,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? auroraInk : auroraCream;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? auroraGreen : auroraBlue;
      }),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: auroraInk,
      contentTextStyle: TextStyle(
        color: auroraWhite,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
