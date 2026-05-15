import 'package:flutter/material.dart';

abstract class AppColors {
  // Ink scale
  static const ink = Color(0xFF14130F);
  static const ink2 = Color(0xFF2A2925);
  static const stone = Color(0xFF6B6760);
  static const stone2 = Color(0xFF9C9789);
  static const stone3 = Color(0xFFB6B0A2);

  // Surface
  static const bone = Color(0xFFFAF7F0);
  static const canvas = Color(0xFFF2EEE3);
  static const line = Color(0xFFECE5D2);
  static const line2 = Color(0xFFF2EBD9);
  static const surface = Color(0xFFFFFFFF);

  // Clay (primary accent)
  static const clay700 = Color(0xFF6E2E12);
  static const clay600 = Color(0xFF8E4220);
  static const clay500 = Color(0xFFB85C32);
  static const clay400 = Color(0xFFC97A4D);
  static const clay300 = Color(0xFFDDA279);
  static const clay200 = Color(0xFFECC3A2);
  static const clay100 = Color(0xFFF6DCC5);
  static const clay50 = Color(0xFFFBEDDD);

  // Ochre
  static const ochre600 = Color(0xFF9C7A18);
  static const ochre500 = Color(0xFFC99A3A);
  static const ochre200 = Color(0xFFECD89E);
  static const ochre100 = Color(0xFFF4E6BD);
  static const ochre50 = Color(0xFFFAF1D8);

  // Sage
  static const sage600 = Color(0xFF4F6E55);
  static const sage500 = Color(0xFF6E8E72);
  static const sage200 = Color(0xFFC4D2C0);
  static const sage100 = Color(0xFFDDE5DA);
  static const sage50 = Color(0xFFEEF2EC);

  // Rose
  static const rose600 = Color(0xFF9C4A3F);
  static const rose500 = Color(0xFFC97A6E);
  static const rose100 = Color(0xFFF3D8D2);
  static const rose50 = Color(0xFFFAEAE6);

  // Neutral chips
  static const neutral100 = Color(0xFFF0EBDE);
  static const neutral200 = Color(0xFFE4DDC9);

  // Semantic shortcuts
  static const upToDate = sage500;
  static const dueSoon = ochre500;
  static const overdue = rose500;
  static const background = bone;
  static const border = line;
  static const textDisabled = stone3;

  // Legacy aliases kept for compatibility
  static const surfaceVariant = clay50;
  static const textPrimary = ink;
  static const textSecondary = stone;
}
