import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Luxury Medical Palette
  static const Color primaryBlue = Color(0xFF1677FF);
  static const Color primary = primaryBlue;
  static const Color primaryDarkBlue = Color(0xFF0F4C81);
  static const Color primaryCyan = Color(0xFF00C6FF);
  static const Color accentTeal = Color(0xFF06B6D4);
  static const Color emeraldTeal = Color(0xFF0D9488);

  // Status & Lifecycle Colors
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successDarkBg = Color(0xFF064E3B);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningDarkBg = Color(0xFF78350F);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerDarkBg = Color(0xFF7F1D1D);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleBg = Color(0xFFF5F3FF);

  static const Color info = Color(0xFF0EA5E9);
  static const Color infoBg = Color(0xFFF0F9FF);

  // Light Luxury Palette (Crisp Clinical)
  static const Color lightScaffold = Color(0xFFF4F8FC);
  static const Color lightCard = Colors.white;
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF071A2B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightInputFill = Color(0xFFF8FAFC);
  static const Color lightDivider = Color(0xFFEDF2F7);

  // Dark Luxury Palette (Premium Deep Midnight Slate)
  static const Color darkScaffold = Color(0xFF0B1120);
  static const Color darkCard = Color(0xFF151F32);
  static const Color darkSurface = Color(0xFF1E2B45);
  static const Color darkBorder = Color(0xFF293B57);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFA5B4CB);
  static const Color darkInputFill = Color(0xFF0F1829);
  static const Color darkDivider = Color(0xFF22324C);

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1677FF), Color(0xFF00C6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF0F1E2E), Color(0xFF14273A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dynamic Helpers based on Brightness / Context
  static Color scaffoldBg(BuildContext context) {
    return isDark(context) ? darkScaffold : lightScaffold;
  }

  static Color cardBg(BuildContext context) {
    return isDark(context) ? darkCard : lightCard;
  }

  static Color surfaceBg(BuildContext context) {
    return isDark(context) ? darkSurface : lightSurface;
  }

  static Color border(BuildContext context) {
    return isDark(context) ? darkBorder : lightBorder;
  }

  static Color textPrimary(BuildContext context) {
    return isDark(context) ? darkTextPrimary : lightTextPrimary;
  }

  static Color textSecondary(BuildContext context) {
    return isDark(context) ? darkTextSecondary : lightTextSecondary;
  }

  static Color inputFill(BuildContext context) {
    return isDark(context) ? darkInputFill : lightInputFill;
  }

  static Color divider(BuildContext context) {
    return isDark(context) ? darkDivider : lightDivider;
  }

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
