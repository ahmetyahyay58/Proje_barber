import 'package:flutter/material.dart';

/// Desktop/web'de fare üzerine gelince hafif yükselme + gölge animasyonu.
/// Mobile'da da sorunsuz çalışır (hover tetiklenmez).
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.hoverOffsetY = -6,
    this.hoverScale = 1.02,
    this.duration = const Duration(milliseconds: 220),
  });

  final Widget child;
  final double hoverOffsetY;
  final double hoverScale;
  final Duration duration;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = const Color(0xFFFFB300);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TweenAnimationBuilder<double>(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0.0, end: _hovered ? 1.0 : 0.0),
        builder: (context, t, child) {
          final shadowSecondaryAlpha = 0.25 * t;
          final shadowAccentAlpha = 0.15 * t;

          return Transform.translate(
            offset: Offset(0, widget.hoverOffsetY * t),
            child: Transform.scale(
              scale: 1.0 + (widget.hoverScale - 1.0) * t,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.secondary.withValues(alpha: shadowSecondaryAlpha),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: accent.withValues(alpha: shadowAccentAlpha),
                      blurRadius: 52,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

