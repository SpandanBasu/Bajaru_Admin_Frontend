import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get h3 => GoogleFonts.poppins(
        fontSize: 17, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ── Body ─────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySemiBold => GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ── Caption ───────────────────────────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get captionMedium => GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get captionBold => GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      );

  // ── Label ─────────────────────────────────────────────────────────────────
  static TextStyle get label => GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  // ── Stat ─────────────────────────────────────────────────────────────────
  static TextStyle get statValue => GoogleFonts.poppins(
        fontSize: 26, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );
}
