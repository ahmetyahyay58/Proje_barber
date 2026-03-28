import 'package:flutter/material.dart';

import '../../app/routes.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF020617),
                Color(0xFF020617),
                Color(0xFF020617),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _LogoHeader(colorScheme: scheme),
                const SizedBox(height: 32),
                Text(
                  'RANDEVU SİSTEMİNİ\nSANAL DÜNYAYA TAŞIYORUZ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                ),
                const SizedBox(height: 32),
                _RoleCard(
                  title: 'Müşteriyim',
                  subtitle:
                      'Şehir / ilçe filtrele, berberleri sırala, hemen randevu al.',
                  icon: Icons.person_outline,
                  isPrimary: true,
                  onTap: () => Navigator.of(context).pushNamed(
                    Routes.customerLogin,
                  ),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'Berberim',
                  subtitle:
                      'Randevularını yönet, fiyat listesini düzenle, izin günlerini ayarla.',
                  icon: Icons.storefront_outlined,
                  isPrimary: false,
                  onTap: () => Navigator.of(context).pushNamed(
                    Routes.barberLogin,
                  ),
                ),
                const Spacer(),
                Text(
                  'Bu proje demo amaçlıdır, veriler cihaz üzerinde tutulur.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  const _LogoHeader({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFFFB300);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.45),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: const Icon(
                Icons.content_cut,
                size: 56,
                color: Colors.black,
              ),
            ),
            Positioned(
              bottom: -10,
              right: -10,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.language,
                  size: 22,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
            children: const [
              TextSpan(text: 'BERBER'),
              TextSpan(
                text: 'PRO',
                style: TextStyle(
                  color: Color(0xFFFFB300),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? Colors.white : const Color(0xFF020617);
    final titleColor = isPrimary ? const Color(0xFF020617) : Colors.white;
    final subtitleColor =
        isPrimary ? const Color(0xFF4B5563) : Colors.white.withValues(alpha: 0.78);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? const Color(0xFFF3F4FF)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isPrimary
                      ? const Color(0xFF020617)
                      : Colors.white.withValues(alpha: 0.94),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: subtitleColor,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: isPrimary
                    ? const Color(0xFF020617)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

