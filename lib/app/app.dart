import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'routes.dart';

import '../features/splash/splash_screen.dart';
import '../features/auth/role_select_screen.dart';
import '../features/auth/customer_login_screen.dart';
import '../features/auth/barber_login_screen.dart';
import '../features/barber/barber_shell.dart';
import '../features/customer/customer_shell.dart';

class ProjectBarberApp extends StatelessWidget {
  const ProjectBarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    /// Ana tema: rgb(96, 124, 138) — lacivert yerine gri-mavi ton.
    const themeBaseGray = Color.fromRGBO(96, 124, 138, 1);
    const accent = Color(0xFFFFB300);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: themeBaseGray,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      onPrimary: const Color(0xFF1C1C1C),
      secondary: themeBaseGray,
      onSecondary: Colors.white,
    );

    final baseDark = ThemeData(brightness: Brightness.dark);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      baseDark.textTheme,
    ).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Barber',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF2B2B2B),
        textTheme: textTheme,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            foregroundColor: const Color(0xFF0B0F1A),
            backgroundColor: accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            textStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.45),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accent.withValues(alpha: 0.9)),
          ),
          labelStyle: textTheme.bodyMedium,
          floatingLabelStyle: textTheme.bodySmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: colorScheme.surfaceContainerHighest,
          selectedColor: accent.withValues(alpha: 0.28),
          labelStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: colorScheme.outline.withValues(alpha: 0.2),
          thickness: 1,
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: colorScheme.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (_) => const SplashScreen(),
        Routes.roleSelect: (_) => const RoleSelectScreen(),
        Routes.customerLogin: (_) => const CustomerLoginScreen(),
        Routes.barberLogin: (_) => const BarberLoginScreen(),
        Routes.barberShell: (_) => const BarberShell(),
        Routes.customerShell: (_) => const CustomerShell(),
      },
    );
  }
}

