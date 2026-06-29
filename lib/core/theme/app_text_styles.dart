import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge = GoogleFonts.inter(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.12,
      letterSpacing: -1.25);
  static TextStyle displayMedium = GoogleFonts.inter(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.16,
      letterSpacing: -0.9);
  static TextStyle displaySmall = GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.2,
      letterSpacing: -0.35);
  static TextStyle headlineLarge = GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.25,
      letterSpacing: -0.35);
  static TextStyle headlineMedium = GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.3,
      letterSpacing: -0.2);
  static TextStyle headlineSmall = GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.35,
      letterSpacing: -0.1);
  static TextStyle bodyLarge = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.45);
  static TextStyle bodyMedium = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.45);
  static TextStyle bodySmall = GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.4);
  static TextStyle labelLarge = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.2);
  static TextStyle labelMedium = GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      height: 1.2);
  static TextStyle labelSmall = GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
      height: 1.2);
  static TextStyle neonTitle = displayMedium;
  static TextStyle consoleBadge = GoogleFonts.inter(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: 0.45);
  static TextStyle rating = GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.goldenYellow);
  static TextStyle gameTitle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.25);
  static TextStyle gameMeta = GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted);
}
