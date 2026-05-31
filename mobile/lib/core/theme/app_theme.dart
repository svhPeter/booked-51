import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary brand — Stitch Sapphire Medical Blue
  static const Color primary = Color(0xFF0F52BA);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF003C90);
  static const Color primarySurface = Color(0xFFD9E2FF);

  // Semantic — Stitch Calm Teal
  static const Color secondary = Color(0xFF0D9488);
  static const Color secondarySurface = Color(0xFF86F2E4);

  static const Color accent = Color(0xFF3D4143);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorSurface = Color(0xFFFFDAD6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF3B82F6);

  // Light surfaces — Stitch warm neutrals
  static const Color background = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceVariant = Color(0xFFD5E3FC);
  static const Color surfaceDim = Color(0xFFCCDBF3);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkNavBar = Color(0xFF0F172A);

  // Light text
  static const Color textPrimary = Color(0xFF0D1C2E);
  static const Color textSecondary = Color(0xFF434653);
  static const Color textTertiary = Color(0xFF737784);
  static const Color textHint = Color(0xFF737784);

  // Dark text
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkTextHint = Color(0xFF64748B);

  // Chrome
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFF1F5F9);
  static const Color shadow = Color(0x0A000000);

  // Dark chrome
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);

  // Status
  static const Color rating = Color(0xFFF59E0B);
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF94A3B8);
  static const Color verified = Color(0xFF0D9488);

  // Status chips — matching Stitch spec
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusPendingBg = Color(0xFFFEF3C7);
  static const Color statusConfirmed = Color(0xFF0D9488);
  static const Color statusConfirmedBg = Color(0xFFD1FAE5);
  static const Color statusCompleted = Color(0xFF64748B);
  static const Color statusCompletedBg = Color(0xFFF1F5F9);
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusCancelledBg = Color(0xFFFEE2E2);
}

class AppShadows {
  // Stitch Level 1
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0D0F172A), blurRadius: 3, offset: Offset(0, 1)),
  ];
  // Stitch Level 2
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 15, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x080F172A), blurRadius: 3, offset: Offset(0, -3)),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x080F172A), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> darkSm = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> darkMd = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, -3)),
  ];
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF003C90),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF0F52BA),
      onPrimaryContainer: Color(0xFFBCDEFF),
      secondary: Color(0xFF006A61),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF86F2E4),
      onSecondaryContainer: Color(0xFF006F66),
      tertiary: Color(0xFF3D4143),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF55585A),
      onTertiaryContainer: Color(0xFFCCCED0),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: Color(0xFFF8F9FF),
      onSurface: Color(0xFF0D1C2E),
      onSurfaceVariant: Color(0xFF434653),
      outline: Color(0xFF737784),
      outlineVariant: Color(0xFFC3C6D5),
      shadow: Color(0x0D0F172A),
      surfaceTint: Color(0xFF1D59C1),
      inverseSurface: Color(0xFF233144),
      inversePrimary: Color(0xFFB0C6FF),
      surfaceDim: Color(0xFFCCDBF3),
      surfaceBright: Color(0xFFF8F9FF),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFEFF4FF),
      surfaceContainer: Color(0xFFE6EEFF),
      surfaceContainerHigh: Color(0xFFDCE9FF),
      surfaceContainerHighest: Color(0xFFD5E3FC),
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.02),
      displayMedium: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3, letterSpacing: -0.01),
      displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3),
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3),
      headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4),
      headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4),
      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.normal, color: AppColors.textPrimary, height: 1.6),
      bodyMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textSecondary, height: 1.5),
      bodySmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textTertiary, height: 1.5),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.01),
      labelMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.01),
      labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textTertiary, letterSpacing: 0.02),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F52BA),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF0F52BA).withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white60,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        surfaceTintColor: Colors.transparent,
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return Colors.white.withValues(alpha: 0.15);
          return null;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0F52BA),
        side: const BorderSide(color: Color(0xFFC3C6D5), width: 1.5),
        disabledForegroundColor: AppColors.textHint,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return const Color(0xFF0F52BA).withValues(alpha: 0.08);
          return null;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF0F52BA),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return const Color(0xFF0F52BA).withValues(alpha: 0.08);
          return null;
        }),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8F9FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F52BA), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 14),
      labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
      helperStyle: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12),
      errorStyle: GoogleFonts.inter(color: AppColors.error, fontSize: 12),
      prefixIconColor: AppColors.textTertiary,
      suffixIconColor: AppColors.textTertiary,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: const Color(0xFFF8F9FF),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFFF8F9FF),
      indicatorColor: AppColors.primarySurface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      height: 65,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textHint,
      )),
      iconTheme: WidgetStatePropertyAll(IconThemeData(
        size: 24,
        color: AppColors.textHint,
      )),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Color(0xFF0F52BA),
      unselectedLabelColor: Color(0xFF737784),
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      indicatorColor: Color(0xFF0F52BA),
      indicatorSize: TabBarIndicatorSize.tab,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFF8F9FF),
      selectedItemColor: Color(0xFF0F52BA),
      unselectedItemColor: Color(0xFF737784),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF8F9FF),
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
      actionsIconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF8F9FF),
      selectedColor: AppColors.primarySurface.withValues(alpha: 0.6),
      labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
      secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      selectedShadowColor: Colors.transparent,
      showCheckmark: false,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF0F52BA),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      backgroundColor: const Color(0xFF0D1C2E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actionTextColor: const Color(0xFF3B82F6),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      contentTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textSecondary, height: 1.5),
      backgroundColor: const Color(0xFFF8F9FF),
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      backgroundColor: Color(0xFFF8F9FF),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      color: const Color(0xFFF8F9FF),
      textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF0F52BA);
        return AppColors.textHint;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF0F52BA).withValues(alpha: 0.3);
        return const Color(0xFFE2E8F0);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF0F52BA);
        return Colors.transparent;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF0F52BA);
        return AppColors.textHint;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF0F52BA),
      linearTrackColor: Color(0xFFD5E3FC),
      circularTrackColor: Color(0xFFD5E3FC),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      subtitleTextStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
      leadingAndTrailingTextStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textTertiary),
    ),
    tooltipTheme: TooltipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1C2E),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF3B82F6),
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6),
      onPrimary: Color(0xFF0F172A),
      primaryContainer: Color(0xFF1E3A5F),
      onPrimaryContainer: Color(0xFFB0C6FF),
      secondary: Color(0xFF0D9488),
      onSecondary: Color(0xFF0F172A),
      secondaryContainer: Color(0xFF064E3B),
      onSecondaryContainer: Color(0xFF6BD8CB),
      tertiary: Color(0xFFE0E3E5),
      onTertiary: Color(0xFF191C1E),
      tertiaryContainer: Color(0xFF55585A),
      onTertiaryContainer: Color(0xFFCCCED0),
      error: Color(0xFFFCA5A5),
      onError: Color(0xFF0F172A),
      errorContainer: Color(0xFF450A0A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF1E293B),
      onSurface: Color(0xFFF1F5F9),
      onSurfaceVariant: Color(0xFFCBD5E1),
      outline: Color(0xFF334155),
      outlineVariant: Color(0xFF1E293B),
      shadow: Color(0x4D000000),
      surfaceTint: Color(0xFF3B82F6),
      inverseSurface: Color(0xFFF1F5F9),
      inversePrimary: Color(0xFF0F52BA),
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary, height: 1.2, letterSpacing: -0.02),
      displayMedium: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary, height: 1.3, letterSpacing: -0.01),
      displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary, height: 1.3),
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary, height: 1.3),
      headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary, height: 1.4),
      headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary, height: 1.4),
      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkTextPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.normal, color: AppColors.darkTextPrimary, height: 1.6),
      bodyMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.darkTextSecondary, height: 1.5),
      bodySmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.darkTextTertiary, height: 1.5),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkBackground, letterSpacing: 0.01),
      labelMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkTextSecondary, letterSpacing: 0.01),
      labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.darkTextTertiary, letterSpacing: 0.02),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: AppColors.darkBackground,
        disabledBackgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        disabledForegroundColor: AppColors.darkTextTertiary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        surfaceTintColor: Colors.transparent,
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return AppColors.darkBackground.withValues(alpha: 0.2);
          return null;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF3B82F6),
        side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        disabledForegroundColor: AppColors.darkTextTertiary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return const Color(0xFF3B82F6).withValues(alpha: 0.1);
          return null;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF3B82F6),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return const Color(0xFF3B82F6).withValues(alpha: 0.1);
          return null;
        }),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFCA5A5), width: 2),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.darkTextHint, fontSize: 14),
      labelStyle: GoogleFonts.inter(color: AppColors.darkTextSecondary, fontSize: 14),
      helperStyle: GoogleFonts.inter(color: AppColors.darkTextTertiary, fontSize: 12),
      errorStyle: GoogleFonts.inter(color: const Color(0xFFFCA5A5), fontSize: 12),
      prefixIconColor: AppColors.darkTextTertiary,
      suffixIconColor: AppColors.darkTextTertiary,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
      color: AppColors.darkCard,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.darkBackground,
      indicatorColor: Color(0xFF1E3A5F),
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      height: 65,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextTertiary,
      )),
      iconTheme: WidgetStatePropertyAll(IconThemeData(
        size: 24,
        color: AppColors.darkTextTertiary,
      )),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Color(0xFF3B82F6),
      unselectedLabelColor: Color(0xFF64748B),
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      indicatorColor: Color(0xFF3B82F6),
      indicatorSize: TabBarIndicatorSize.tab,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkBackground,
      selectedItemColor: Color(0xFF3B82F6),
      unselectedItemColor: AppColors.darkTextHint,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary, size: 22),
      actionsIconTheme: const IconThemeData(color: AppColors.darkTextSecondary, size: 22),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedColor: const Color(0xFF1E3A5F),
      labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.darkTextSecondary),
      secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF3B82F6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: AppColors.darkBorder),
      selectedShadowColor: Colors.transparent,
      showCheckmark: false,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.darkDivider, thickness: 1, space: 1),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF3B82F6),
      foregroundColor: AppColors.darkBackground,
      elevation: 4,
      shape: CircleBorder(),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      backgroundColor: AppColors.darkSurfaceVariant,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actionTextColor: const Color(0xFF3B82F6),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      contentTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.darkTextSecondary, height: 1.5),
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      backgroundColor: AppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      color: AppColors.darkSurface,
      textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkTextPrimary),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF3B82F6);
        return AppColors.darkTextTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF3B82F6).withValues(alpha: 0.3);
        return AppColors.darkBorder;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF3B82F6);
        return Colors.transparent;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF3B82F6);
        return AppColors.darkTextTertiary;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF3B82F6),
      linearTrackColor: Color(0xFF1E3A5F),
      circularTrackColor: Color(0xFF1E3A5F),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.darkTextPrimary),
      subtitleTextStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.darkTextSecondary),
      leadingAndTrailingTextStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkTextTertiary),
    ),
    tooltipTheme: TooltipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

extension ThemeColors on BuildContext {
  Brightness get _brightness => Theme.of(this).brightness;

  bool get isDarkMode => _brightness == Brightness.dark;

  Color get surfaceColor => isDarkMode ? AppColors.darkSurface : AppColors.surface;

  Color get surfaceVariantColor => isDarkMode ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

  Color get textPrimaryColor => isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get textSecondaryColor => isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get textTertiaryColor => isDarkMode ? AppColors.darkTextTertiary : AppColors.textTertiary;

  Color get borderColor => isDarkMode ? AppColors.darkBorder : AppColors.border;

  Color get dividerColor => isDarkMode ? AppColors.darkDivider : AppColors.divider;

  Color get primarySurfaceColor => isDarkMode ? const Color(0xFF1E3A5F) : AppColors.primarySurface;

  Color get warningSurfaceColor => isDarkMode ? const Color(0xFF422006) : AppColors.warningSurface;

  Color get errorSurfaceColor => isDarkMode ? const Color(0xFF450A0A) : AppColors.errorSurface;

  Color get secondarySurfaceColor => isDarkMode ? const Color(0xFF064E3B) : AppColors.secondarySurface;

  Color get cardShadowColor => isDarkMode ? const Color(0x4D000000) : AppColors.shadow;

  Color get successColor => isDarkMode ? AppColors.secondary : AppColors.secondary;

  Color get warningColor => AppColors.warning;

  Color get errorColor => isDarkMode ? const Color(0xFFFCA5A5) : AppColors.error;

  Color get scaffoldBackgroundColor =>
      isDarkMode ? AppColors.darkBackground : AppColors.background;
}

class StitchSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

class StitchRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 20;
}
