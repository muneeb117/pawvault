import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Themed date picker that matches the bone/ink design system.
Future<DateTime?> pickPawDate(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2000),
    lastDate: lastDate ?? DateTime.now(),
    builder: (ctx, child) {
      return Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.ink,
            onPrimary: AppColors.bone,
            surface: AppColors.bone,
            onSurface: AppColors.ink,
            secondary: AppColors.clay500,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.bone,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: AppColors.bone,
            surfaceTintColor: AppColors.bone,
            headerBackgroundColor: AppColors.bone,
            headerForegroundColor: AppColors.ink,
            headerHeadlineStyle: GoogleFonts.bricolageGrotesque(
              fontSize: 32, fontWeight: FontWeight.w600,
              color: AppColors.ink, letterSpacing: -0.8,
            ),
            headerHelpStyle: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.stone2, letterSpacing: 0.5,
            ),
            weekdayStyle: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.stone2,
            ),
            dayStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink,
            ),
            yearStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink,
            ),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.bone;
              if (states.contains(WidgetState.disabled)) return AppColors.stone3;
              return AppColors.ink;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.ink;
              return Colors.transparent;
            }),
            todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.ink;
              return AppColors.clay50;
            }),
            todayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.bone;
              return AppColors.clay600;
            }),
            todayBorder: const BorderSide(color: AppColors.clay500, width: 1),
            yearForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.bone;
              return AppColors.ink;
            }),
            yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.ink;
              return Colors.transparent;
            }),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: AppColors.stone,
              textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: AppColors.ink,
              textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            dividerColor: AppColors.line,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink,
              textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}
