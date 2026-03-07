import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.roleSelect);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.12),
              scheme.secondary.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -30,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.secondary.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary,
                            scheme.secondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.25),
                            blurRadius: 28,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.content_cut,
                        size: 62,
                        color: scheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Project Barber',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Şehrindeki en iyi berberi bul,\nkolayca randevu oluştur.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _Chip(label: 'Online Randevu'),
                        _Chip(label: 'Şehir / İlçe Filtreleme'),
                        _Chip(label: 'Berber Paneli'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

