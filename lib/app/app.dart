import 'package:flutter/material.dart';

import 'app_theme.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Berber Pro',
      theme: AppTheme.build(),
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
