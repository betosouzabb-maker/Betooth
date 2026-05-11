import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

abstract final class AppTypography {
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.outfit(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    ),
    displayMedium: GoogleFonts.outfit(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    ),
    displaySmall: GoogleFonts.outfit(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: GoogleFonts.outfit(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: GoogleFonts.outfit(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: GoogleFonts.outfit(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: GoogleFonts.outfit(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w400,
    ),
  );
}