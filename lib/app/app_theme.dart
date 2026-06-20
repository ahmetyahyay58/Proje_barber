import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium berber/salon — koyu mod ana tema, sıcak gri ara tonlar.
abstract final class AppTheme {
  // Ana yüzeyler: koyu mod (saf siyah değil, sıcak kömür gri)
  static const surfaceDeep = Color(0xFF23221F);
  static const surfaceBase = Color(0xFF2C2B28);
  static const surfaceRaised = Color(0xFF353430);
  static const surfaceOverlay = Color(0xFF3E3D39);

  // Ara tonlar: sevilen sıcak gri — kenarlık, ikincil metin, vurgu arası
  static const grayAccent = Color(0xFFA8A6A2);
  static const graySoft = Color(0xFFB6B4B0);
  static const grayMuted = Color(0xFF7A7874);

  // Vurgu: bronz & latte
  static const accent = Color(0xFFBE9B6E);
  static const accentSoft = Color(0xFFC8AD86);
  static const cream = Color(0xFFBFB3A2);
  static const bronze = Color(0xFF91785C);
  static const latte = Color(0xFFB09A78);

  // Tipografi (koyu zemin üzerinde)
  static const textPrimary = Color(0xFFEEEDEB);
  static const textSecondary = Color(0xFFA8A6A2);
  static const textMuted = Color(0xFF7A7874);

  // Sınırlar — sıcak gri ara ton
  static const borderLight = Color(0xFF5C5B57);
  static const borderSubtle = Color(0xFF4A4946);

  static const success = Color(0xFF5A9A7A);
  static const error = Color(0xFFC97A72);
  static const info = Color(0xFF6B8FAD);

  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radiusLg = 20.0;
  static const radiusXl = 24.0;

  static const spacingXs = 8.0;
  static const spacingSm = 12.0;
  static const spacingMd = 16.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;

  static double shellTopInset(BuildContext context) {
    return MediaQuery.paddingOf(context).top + kToolbarHeight + spacingSm;
  }

  static ThemeData build() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      onPrimary: const Color(0xFF1E1D1A),
      secondary: grayAccent,
      onSecondary: textPrimary,
      surface: surfaceRaised,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceOverlay,
      surfaceContainerHigh: surfaceBase,
      surfaceContainer: surfaceBase,
      outline: grayAccent.withValues(alpha: 0.45),
      error: error,
    );

    final baseDark = ThemeData(brightness: Brightness.dark);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseDark.textTheme)
        .apply(bodyColor: textPrimary, displayColor: textPrimary)
        .copyWith(
          headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.15,
            color: textPrimary,
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.2,
            color: textPrimary,
          ),
          headlineSmall: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.25,
            color: textPrimary,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1.3,
            color: textPrimary,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: textPrimary,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: textPrimary,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: textSecondary,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: textMuted,
          ),
          labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: textPrimary,
          ),
        );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: surfaceDeep,
      textTheme: textTheme,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceRaised.withValues(alpha: 0.97),
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleSpacing: spacingMd,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: textPrimary, size: 24),
      ),
      cardTheme: CardThemeData(
        color: surfaceRaised,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: grayAccent.withValues(alpha: 0.28)),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: accent,
          disabledBackgroundColor: accent.withValues(alpha: 0.35),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentSoft,
          side: BorderSide(color: grayAccent.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: grayAccent.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: error.withValues(alpha: 0.55)),
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: grayAccent.withValues(alpha: 0.12),
        selectedColor: accent.withValues(alpha: 0.22),
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: BorderSide(color: grayAccent.withValues(alpha: 0.3)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: grayAccent.withValues(alpha: 0.22),
        thickness: 1,
        space: 1,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        width: 300,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(radiusXl)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: borderLight),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceOverlay,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return accent.withValues(alpha: 0.16);
            }
            return grayAccent.withValues(alpha: 0.1);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accentSoft;
            return textSecondary;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: grayAccent.withValues(alpha: 0.3)),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSm),
            ),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: spacingMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return grayMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withValues(alpha: 0.28);
          }
          return grayAccent.withValues(alpha: 0.25);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accentSoft,
        unselectedLabelColor: textMuted,
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),
    );
  }

  static List<BoxShadow> softShadow({double opacity = 0.08, double blur = 20}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity * 2.2),
        blurRadius: blur,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: grayAccent.withValues(alpha: 0.06),
        blurRadius: blur * 1.2,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static BoxDecoration glassCard({Color? tint, bool selected = false}) {
    return BoxDecoration(
      color: tint ?? surfaceRaised,
      borderRadius: BorderRadius.circular(radiusLg),
      border: Border.all(
        color: selected
            ? accent.withValues(alpha: 0.55)
            : grayAccent.withValues(alpha: 0.28),
        width: selected ? 1.5 : 1,
      ),
      boxShadow: selected
          ? [
              ...softShadow(opacity: 0.12, blur: 24),
              BoxShadow(
                color: accent.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ]
          : softShadow(opacity: 0.06, blur: 16),
    );
  }

  static BoxDecoration gradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          surfaceBase,
          surfaceDeep,
          const Color(0xFF1C1B18),
          grayAccent.withValues(alpha: 0.08),
        ],
        stops: const [0.0, 0.45, 0.85, 1.0],
      ),
    );
  }

  static const weekdayShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
}
