import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.ink,
          onPrimary: AppColors.bone,
          secondary: AppColors.clay500,
          onSecondary: AppColors.bone,
          error: AppColors.rose500,
          onError: AppColors.bone,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
        ),
        scaffoldBackgroundColor: AppColors.bone,
        textTheme: _textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bone,
          foregroundColor: AppColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.notoSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.stone2,
            letterSpacing: 0.08 * 13,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.bone,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            textStyle: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.01 * 14,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            textStyle: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.neutral100,
          labelStyle: GoogleFonts.notoSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.ink2,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.clay500, width: 1.5),
          ),
          hintStyle: GoogleFonts.notoSans(
            color: AppColors.stone2,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  static TextTheme get _textTheme => TextTheme(
        displayLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -1.5,
        ),
        displayMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -1.0,
        ),
        displaySmall: GoogleFonts.bricolageGrotesque(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -0.8,
        ),
        headlineLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -1.4,
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -0.6,
        ),
        headlineSmall: GoogleFonts.bricolageGrotesque(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -0.4,
        ),
        titleLarge: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleMedium: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleSmall: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        bodyLarge: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
        ),
        bodyMedium: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
        ),
        bodySmall: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.stone,
        ),
        labelLarge: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        labelMedium: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.stone,
        ),
        labelSmall: GoogleFonts.notoSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.stone2,
          letterSpacing: 0.14 * 10,
        ),
      );
}
