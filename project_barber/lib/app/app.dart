import 'package:flutter/material.dart';

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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1), // morumsu ana renk
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Barber',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: const CardThemeData(),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
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

