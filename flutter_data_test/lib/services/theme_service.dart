// Theme configuration for Aurora TV app
import 'package:flutter/material.dart';
import '../constants/colors.dart';

ThemeData buildAuroraTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: auroraNavy,
    colorScheme: ColorScheme.fromSeed(
      seedColor: auroraBlueTeal,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: auroraMint,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
      iconTheme: IconThemeData(color: auroraMint),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: auroraPanel,
      hintStyle: const TextStyle(color: Colors.white54),
      labelStyle: const TextStyle(color: auroraLight),
      prefixIconColor: auroraGlow,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: auroraDeep, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: auroraGlow, width: 1.8),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: auroraBlueTeal,
        foregroundColor: auroraMint,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    ),
  );
}
