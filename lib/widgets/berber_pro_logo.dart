import 'package:flutter/material.dart';

/// Çıktı **tam daire** — dikdörtgen kutu / köşelerdeki beyaz alan görünmez.
/// Uygulamanın her yerinde aynı etkileşim için hover / basma animasyonu içerir.
class BerberProLogo extends StatefulWidget {
  const BerberProLogo({
    super.key,
    this.width = 200,
  });

  /// Daire çapı (genişlik = yükseklik).
  final double width;

  @override
  State<BerberProLogo> createState() => _BerberProLogoState();
}

class _BerberProLogoState extends State<BerberProLogo> {
  static const _anim = Duration(milliseconds: 260);
  static const Curve _curve = Curves.easeOutCubic;

  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.width;

    final scale = _pressed
        ? 0.95
        : (_hover ? 1.06 : 1.0);
    final y = _pressed
        ? 3.0
        : (_hover ? -4.0 : 0.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedSlide(
          duration: _anim,
          curve: _curve,
          offset: Offset(0, y / 32),
          child: AnimatedScale(
            duration: _anim,
            curve: _curve,
            scale: scale,
            child: AnimatedContainer(
              duration: _anim,
              curve: _curve,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  if (_hover || _pressed)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                ],
              ),
              child: SizedBox(
                width: d,
                height: d,
                child: ClipOval(
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/deneme22logo.png',
                    width: d,
                    height: d,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
