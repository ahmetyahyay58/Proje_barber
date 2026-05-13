import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../widgets/berber_pro_logo.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(scaffoldBg, scheme.secondary, 0.14)!,
                scaffoldBg,
                Color.lerp(scaffoldBg, scheme.secondary, 0.08)!,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColoredBox(
                      color: scheme.secondary.withValues(alpha: 0.14),
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
                      color: Colors.white.withValues(alpha: 0.12),
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
                const Spacer(),
                Text(
                  'Kayıtlar bulutta tutulur ve e-posta koduyla doğrulanır.',
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

  static const Color _accent = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = widget.isPrimary ? Colors.white : Colors.black;
    final titleColor =
        widget.isPrimary ? scheme.onInverseSurface : Colors.white;
    final subtitleColor = widget.isPrimary
        ? scheme.onInverseSurface.withValues(alpha: 0.62)
        : Colors.white.withValues(alpha: 0.78);

    final hoverGlow = widget.isPrimary
        ? scheme.secondary.withValues(alpha: 0.42)
        : _accent.withValues(alpha: 0.5);
    final borderGlow = widget.isPrimary
        ? scheme.secondary.withValues(alpha: 0.55)
        : _accent.withValues(alpha: 0.65);

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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hover ? borderGlow : Colors.transparent,
              width: _hover ? 1.5 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: _hover
                    ? hoverGlow
                    : Colors.black.withValues(alpha: widget.isPrimary ? 0.07 : 0.35),
                blurRadius: _hover ? 32 : 14,
                spreadRadius: _hover ? 0 : 0,
                offset: Offset(0, _hover ? 14 : 6),
              ),
              if (_hover)
                BoxShadow(
                  color: (widget.isPrimary ? scheme.secondary : _accent)
                      .withValues(alpha: 0.15),
                  blurRadius: 48,
                  offset: const Offset(0, 20),
                ),
            ],
          ),
          child: Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              splashColor: widget.isPrimary
                  ? scheme.secondary.withValues(alpha: 0.22)
                  : _accent.withValues(alpha: 0.28),
              highlightColor: widget.isPrimary
                  ? scheme.secondary.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.1),
              hoverColor: widget.isPrimary
                  ? scheme.secondary.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.07),
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
                        Icons.chevron_right_rounded,
                        size: 26,
                        color: widget.isPrimary
                            ? scheme.onInverseSurface
                            : Colors.white.withValues(alpha: 0.9),
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

