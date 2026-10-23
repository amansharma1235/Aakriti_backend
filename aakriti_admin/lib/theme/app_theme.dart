import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ------------------------------------------------------------
  // LIGHT THEME
  // ------------------------------------------------------------
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightScaffold,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.light,
      surface: AppColors.lightCard,
      onSurface: AppColors.lightTextPrimary,
      primary: AppColors.primaryBlue,
      outline: AppColors.lightBorder,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
    ),

    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightCard,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.lightTextSecondary,
        fontSize: 14,
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.lightCard,
      modalBackgroundColor: AppColors.lightCard,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 4,
      indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.12),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primaryBlue, size: 22);
        }
        return const IconThemeData(color: AppColors.lightTextSecondary, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          );
        }
        return const TextStyle(
          color: AppColors.lightTextSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        );
      }),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightInputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.8),
      ),
      labelStyle: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: 1,
      space: 1,
    ),
  );

  // ------------------------------------------------------------
  // DARK THEME
  // ------------------------------------------------------------
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkScaffold,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.dark,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkTextPrimary,
      primary: const Color(0xFF38BDF8),
      onPrimary: const Color(0xFF0B1120),
      outline: AppColors.darkBorder,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkCard,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
    ),

    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCard,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.darkTextSecondary,
        fontSize: 14,
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkCard,
      modalBackgroundColor: AppColors.darkCard,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkCard,
      elevation: 4,
      indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.25),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFF60A5FA), size: 22);
        }
        return const IconThemeData(color: AppColors.darkTextSecondary, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: Color(0xFF60A5FA),
            fontWeight: FontWeight.w700,
            fontSize: 11,
          );
        }
        return const TextStyle(
          color: AppColors.darkTextSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        );
      }),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkInputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.8),
      ),
      labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
      thickness: 1,
      space: 1,
    ),
  );

  // ------------------------------------------------------------
  // HELPER SHORTCUTS FOR WIDGETS
  // ------------------------------------------------------------
  static Color cardBg(BuildContext context) => AppColors.cardBg(context);
  static Color scaffoldBg(BuildContext context) => AppColors.scaffoldBg(context);
  static Color surfaceBg(BuildContext context) => AppColors.surfaceBg(context);
  static Color border(BuildContext context) => AppColors.border(context);
  static Color textPrimary(BuildContext context) => AppColors.textPrimary(context);
  static Color textSecondary(BuildContext context) => AppColors.textSecondary(context);
  static Color inputFill(BuildContext context) => AppColors.inputFill(context);
  static Color inputBg(BuildContext context) => AppColors.inputFill(context);
  static Color divider(BuildContext context) => AppColors.divider(context);
  static bool isDark(BuildContext context) => AppColors.isDark(context);

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
