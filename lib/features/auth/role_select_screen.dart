import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/routes.dart';
import '../../widgets/berber_pro_logo.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Center(
                  child: BerberProLogo(width: 220),
                ),
                const SizedBox(height: 28),
                Text(
                  'RANDEVU SİSTEMİNİ\nSANAL DÜNYAYA TAŞIYORUZ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 32),
                _RoleCard(
                  title: 'Müşteriyim',
                  subtitle:
                      'Şehir / ilçe filtrele, berberleri sırala, hemen randevu al.',
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColoredBox(
                      color: AppTheme.info.withValues(alpha: 0.14),
                      child: Image.asset(
                        'assets/images/role_customer_logo.png',
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
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
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColoredBox(
                      color: AppTheme.surfaceOverlay,
                      child: Image.asset(
                        'assets/images/role_barber_logo.png',
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  isPrimary: false,
                  onTap: () => Navigator.of(context).pushNamed(
                    Routes.barberLogin,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Kayıtlar bulutta tutulur ve e-posta koduyla doğrulanır.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.isPrimary,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget leading;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  static const _anim = Duration(milliseconds: 240);
  static const Curve _curve = Curves.easeOutCubic;

  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isPrimary
        ? AppTheme.surfaceRaised.withValues(alpha: 0.95)
        : AppTheme.surfaceOverlay.withValues(alpha: 0.7);
    final titleColor = AppTheme.textPrimary;
    final subtitleColor = AppTheme.textSecondary;
    final borderGlow = AppTheme.accent.withValues(alpha: 0.45);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedSlide(
        duration: _anim,
        curve: _curve,
        offset: _hover ? const Offset(0, -0.04) : Offset.zero,
        child: AnimatedContainer(
          duration: _anim,
          curve: _curve,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: _hover ? borderGlow : AppTheme.borderLight,
              width: 1,
            ),
            boxShadow: _hover
                ? AppTheme.softShadow(opacity: 0.35, blur: 28)
                : AppTheme.softShadow(opacity: 0.18, blur: 16),
          ),
          child: Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              splashColor: AppTheme.accent.withValues(alpha: 0.12),
              highlightColor: AppTheme.accent.withValues(alpha: 0.06),
              hoverColor: AppTheme.cream.withValues(alpha: 0.4),
              onTap: () {
                Feedback.forTap(context);
                widget.onTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Row(
                  children: [
                    _HoverScale(
                      hovered: _hover,
                      child: widget.leading,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: _anim,
                            curve: _curve,
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                  letterSpacing: _hover ? 0.15 : 0,
                                ),
                            child: Text(widget.title),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: subtitleColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSlide(
                      duration: _anim,
                      curve: _curve,
                      offset: _hover ? const Offset(0.12, 0) : Offset.zero,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 22,
                        color: _hover ? AppTheme.accent : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hover’da logoyu hafifçe büyütür (web / masaüstü).
class _HoverScale extends StatelessWidget {
  const _HoverScale({
    required this.hovered,
    required this.child,
  });

  final bool hovered;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: hovered ? 1.07 : 1.0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }
}

