import 'package:flutter/material.dart';

import '../../app/routes.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giriş Seçimi'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      child: const Icon(Icons.content_cut),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hoş geldin!\nMüşteri ya da berber olarak devam et.',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Müşteri Girişi',
                subtitle: 'Şehir/ilçe filtrele, berberleri sırala, randevu al',
                icon: Icons.person,
                onTap: () => Navigator.of(context).pushNamed(Routes.customerLogin),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                title: 'Berber Girişi',
                subtitle:
                    'Randevular, eleman yönetimi, fiyat listesi, izin günleri',
                icon: Icons.storefront,
                onTap: () => Navigator.of(context).pushNamed(Routes.barberLogin),
              ),
              const Spacer(),
              Text(
                'Not: Şimdilik girişler demo amaçlıdır.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

