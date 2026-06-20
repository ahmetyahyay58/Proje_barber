import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Çıktı **tam daire** — dikdörtgen kutu / köşelerdeki beyaz alan görünmez.
/// Sabit görünüm; etrafında hafif dekoratif çerçeve.
class BerberProLogo extends StatelessWidget {
  const BerberProLogo({
    super.key,
    this.width = 200,
  });

  /// Daire çapı (genişlik = yükseklik).
  final double width;

  @override
  Widget build(BuildContext context) {
    final d = width;
    final framePad = d * 0.12;

    return SizedBox(
      width: d + framePad * 2,
      height: d + framePad * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dış dekoratif halka
          Container(
            width: d + framePad * 1.6,
            height: d + framePad * 1.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.22),
                width: 1.2,
              ),
            ),
          ),
          // Köşe noktaları
          ..._cornerDots(d, framePad),
          // Ana logo
          Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textPrimary.withValues(alpha: 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/applogoson.png',
                width: d,
                height: d,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _cornerDots(double d, double pad) {
    const angles = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];
    final radius = d / 2 + pad * 0.85;

    return angles.map((angle) {
      return Positioned(
        left: pad + d / 2 + radius * math.cos(angle) - 3,
        top: pad + d / 2 + radius * math.sin(angle) - 3,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accent.withValues(alpha: 0.45),
            border: Border.all(
              color: AppTheme.surfaceRaised.withValues(alpha: 0.6),
              width: 0.8,
            ),
          ),
        ),
      );
    }).toList();
  }
}
