import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _scissorsAppear;
  late final Animation<double> _cutProgress;
  late final Animation<double> _bladeOpen;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.00, 0.28, curve: Curves.elasticOut)),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.00, 0.14, curve: Curves.easeIn)),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.14, 0.32, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.14, 0.34, curve: Curves.easeOutCubic)));

    _scissorsAppear = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.30, 0.46, curve: Curves.easeOutBack)),
    );

    _cutProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.43, 0.97, curve: Curves.easeInCubic)),
    );

    _bladeOpen = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.28, end: 0.52), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.52, end: 0.20), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.20, end: 0.50), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.50, end: 0.18), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.18, end: 0.46), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.46, end: 0.14), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.14, end: 0.35), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.43, 0.97)));

    _ctrl.forward().then((_) {
      if (mounted) Navigator.of(context).pushReplacementNamed(Routes.roleSelect);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Makasın ekran genişliğine orantılı boyutu
    final scissorsSize = size.width * 0.82;

    return Scaffold(
      backgroundColor: AppTheme.surfaceDeep,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final scissorsY = size.height * 0.50 -
              (size.height * 1.30) * _cutProgress.value;
          final panelShift = size.width * 0.60 * _cutProgress.value;
          final contentFade = (1.0 - _cutProgress.value * 2.5).clamp(0.0, 1.0);

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Arka plan ───────────────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.1),
                      radius: 1.4,
                      colors: [const Color(0xFF3C3A30), AppTheme.surfaceDeep],
                    ),
                  ),
                ),
              ),

              // ── Sol panel ────────────────────────────────────────────
              Positioned(
                top: 0, left: -panelShift,
                width: size.width / 2, height: size.height,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppTheme.surfaceDeep, Color(0xFF2D2C28)],
                    ),
                  ),
                ),
              ),

              // ── Sağ panel ────────────────────────────────────────────
              Positioned(
                top: 0, right: -panelShift,
                width: size.width / 2, height: size.height,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [AppTheme.surfaceDeep, Color(0xFF2D2C28)],
                    ),
                  ),
                ),
              ),

              // ── Kesim ışık hattı ─────────────────────────────────────
              if (_cutProgress.value > 0.03)
                Positioned(
                  top: scissorsY + scissorsSize * 0.48,
                  bottom: 0,
                  left: size.width / 2 - 2,
                  width: 4,
                  child: Opacity(
                    opacity: (_cutProgress.value * 2.2).clamp(0.0, 0.8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00BE9B6E),
                            Color(0x99BE9B6E),
                            Color(0xCCEDE4CC),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.55),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Logo + başlık ─────────────────────────────────────────
              Positioned.fill(
                child: Opacity(
                  opacity: contentFade,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: Container(
                            width: 108, height: 108,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFF3E3B33), AppTheme.surfaceDeep],
                              ),
                              border: Border.all(
                                color: AppTheme.accent.withValues(alpha: 0.38),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: 0.22),
                                  blurRadius: 28, spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.content_cut_rounded,
                                  color: AppTheme.accent, size: 46),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleOpacity,
                          child: Column(children: [
                            ShaderMask(
                              shaderCallback: (r) => const LinearGradient(
                                colors: [AppTheme.accentSoft, AppTheme.cream, AppTheme.accent],
                              ).createShader(r),
                              child: const Text('Berber Pro',
                                style: TextStyle(fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white, letterSpacing: -0.8)),
                            ),
                            const SizedBox(height: 7),
                            const Text('Profesyonel Berber Deneyimi',
                              style: TextStyle(fontSize: 13,
                                  color: AppTheme.textSecondary, letterSpacing: 0.6)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Makas (alttan yukarı fırlar) ───────────────────────
              Positioned(
                left: size.width / 2 - scissorsSize / 2,
                top: scissorsY,
                child: Opacity(
                  opacity: _scissorsAppear.value.clamp(0.0, 1.0),
                  child: SizedBox(
                    width: scissorsSize,
                    height: scissorsSize,
                    child: CustomPaint(
                      painter: _MetallicScissorsPainter(
                        spreadAngle: _bladeOpen.value,
                      ),
                    ),
                  ),
                ),
              ),

              // Makas altı altın parlama
              if (_cutProgress.value > 0.03)
                Positioned(
                  left: size.width / 2 - 60,
                  top: scissorsY + scissorsSize * 0.5,
                  child: Opacity(
                    opacity: (_cutProgress.value * 1.6).clamp(0.0, 0.7),
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.65),
                            blurRadius: 60, spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Metalik Berber Makası — Gerçekçi CustomPainter
// ═══════════════════════════════════════════════════════════════════════════

class _MetallicScissorsPainter extends CustomPainter {
  const _MetallicScissorsPainter({required this.spreadAngle});

  /// Bıçak açıklığı radyan cinsinden. 0 = kapalı, ~0.5 = geniş açık.
  final double spreadAngle;

  // ── Boyutlar ────────────────────────────────────────────────────────────
  static const _tipLen    = 110.0; // pivot → uç
  static const _handleLen =  90.0; // pivot → sap halkası merkezi
  static const _wBase     =  18.0; // pivot'ta bıçak yarı-genişliği
  static const _wTip      =   1.2; // uç yarı-genişliği
  static const _handleOR  =  30.0; // sap dış yarıçapı
  static const _handleIR  =  18.0; // sap iç yarıçapı (delik)

  // ── Renkler ─────────────────────────────────────────────────────────────
  static const _c0  = Color(0xFF0E0E0E);
  static const _c1  = Color(0xFF2A2A2A);
  static const _c2  = Color(0xFF555555);
  static const _c3  = Color(0xFF8A8A8A);
  static const _c4  = Color(0xFFB8B8B8);
  static const _c5  = Color(0xFFE0E0E0);
  static const _c6  = Color(0xFFFFFFFF); // specular peak
  static const _c7  = Color(0xFFD8D8D8);
  static const _c9  = Color(0xFF4A4A4A);
  static const _c10 = Color(0xFF1A1A1A);

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, size.height * 0.46);

    // Arka bıçak gölgesi (derinlik için)
    canvas.save();
    canvas.translate(pivot.dx + 4, pivot.dy + 6);
    canvas.rotate(spreadAngle);
    _drawBladeShadow(canvas);
    canvas.restore();

    // Arka bıçak
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(spreadAngle);
    _drawBladeAssembly(canvas, size, isFront: false);
    canvas.restore();

    // Ön bıçak gölgesi
    canvas.save();
    canvas.translate(pivot.dx + 3, pivot.dy + 5);
    canvas.rotate(-spreadAngle);
    _drawBladeShadow(canvas);
    canvas.restore();

    // Ön bıçak
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(-spreadAngle);
    _drawBladeAssembly(canvas, size, isFront: true);
    canvas.restore();

    // Pivot vidası — en üstte
    _drawPivotScrew(canvas, pivot);
  }

  // ── Bıçak gölgesi ────────────────────────────────────────────────────────
  void _drawBladeShadow(Canvas canvas) {
    final path = _buildBladePath();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  // ── Bıçak + sap montajı ──────────────────────────────────────────────────
  void _drawBladeAssembly(Canvas canvas, Size size, {required bool isFront}) {
    final bladePath = _buildBladePath();

    // Gradyan rect (bıçak genişliği boyunca yatay)
    const rect = Rect.fromLTRB(-_wBase, -_tipLen, _wBase, _handleLen);

    // Metalik şerit gradyanı — specular highlight tam ortada
    final metalShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: isFront
          ? const [_c0, _c1, _c2, _c3, _c4, _c5, _c6, _c5, _c4, _c3, _c9, _c10]
          : const [_c0, _c1, _c2, _c3, _c4, _c7, _c5, _c4, _c3, _c2, _c1, _c0],
      stops: const [0.0, 0.05, 0.13, 0.26, 0.40, 0.47, 0.50, 0.53, 0.62, 0.75, 0.88, 1.0],
    ).createShader(rect);

    canvas.drawPath(bladePath, Paint()..shader = metalShader);

    // Bıçak kenar çizgisi (kesme kenarı — sağ taraf, parlak)
    final edgePaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final edgePath = _buildCuttingEdgePath();
    canvas.drawPath(edgePath, edgePaint);

    // Sırt kenarı (sol — ince koyu)
    final spinePaint = Paint()
      ..color = const Color(0x44000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(_buildSpinePath(), spinePaint);

    // Sap halkası
    _drawHandle(canvas, isFront: isFront);
  }

  // ── Bıçak Path ───────────────────────────────────────────────────────────
  // Pivot merkezi (0,0), uç yukarı (-Y), sap aşağı (+Y)
  Path _buildBladePath() {
    const w0 = _wBase;         // pivot'ta genişlik
    const wH = _wBase * 0.75;  // sap boynundaki genişlik
    const tipHalf = _wTip;

    final p = Path();
    p.moveTo(0, -_tipLen);            // UÇ noktası
    // Sağ kenar (kesme kenarı): uçtan uca
    p.cubicTo(
      tipHalf * 2, -_tipLen * 0.65,
      w0 * 0.85,  -_tipLen * 0.20,
      w0,          0,
    );
    // Pivot'tan sap boynuna (sağ)
    p.cubicTo(
      w0,           _handleLen * 0.30,
      wH * 1.1,     _handleLen * 0.60,
      wH * 0.65,    _handleLen,
    );
    // Sap boynundan sola
    p.lineTo(-wH * 0.65, _handleLen);
    // Sol kenar sap boynundan pivota
    p.cubicTo(
      -wH * 1.1,    _handleLen * 0.60,
      -w0,          _handleLen * 0.30,
      -w0,          0,
    );
    // Sol kenar (sırt): pivottan uca
    p.cubicTo(
      -w0 * 0.85,  -_tipLen * 0.20,
      -tipHalf * 2,-_tipLen * 0.65,
      0,           -_tipLen,
    );
    p.close();
    return p;
  }

  // Kesme kenarı (sağ taraf)
  Path _buildCuttingEdgePath() {
    const w0 = _wBase;
    const tipHalf = _wTip;
    return Path()
      ..moveTo(0, -_tipLen)
      ..cubicTo(
        tipHalf * 2,  -_tipLen * 0.65,
        w0 * 0.85,    -_tipLen * 0.20,
        w0,            0,
      );
  }

  // Sırt (sol taraf)
  Path _buildSpinePath() {
    const w0 = _wBase;
    const tipHalf = _wTip;
    return Path()
      ..moveTo(0, -_tipLen)
      ..cubicTo(
        -tipHalf * 2, -_tipLen * 0.65,
        -w0 * 0.85,   -_tipLen * 0.20,
        -w0,           0,
      );
  }

  // ── Sap halkası ──────────────────────────────────────────────────────────
  void _drawHandle(Canvas canvas, {required bool isFront}) {
    const cy = _handleLen + _handleOR + 4;
    final center = const Offset(0, cy);
    final outerRect = Rect.fromCircle(center: center, radius: _handleOR);

    // Dış halka — metalik gradyan
    final ringShader = RadialGradient(
      center: const Alignment(-0.35, -0.4),
      radius: 1.0,
      colors: isFront
          ? const [Color(0xFFDDDDDD), Color(0xFF999999), Color(0xFF505050), Color(0xFF1A1A1A)]
          : const [Color(0xFFBBBBBB), Color(0xFF707070), Color(0xFF353535), Color(0xFF0E0E0E)],
      stops: const [0.0, 0.35, 0.70, 1.0],
    ).createShader(outerRect);

    canvas.drawCircle(center, _handleOR, Paint()..shader = ringShader);

    // Dış çember kenar gölgesi
    canvas.drawCircle(
      center, _handleOR,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // İç delik — koyu mat
    canvas.drawCircle(center, _handleIR, Paint()..color = const Color(0xFF0D0D0D));

    // İç delik kenar (ince metalik)
    canvas.drawCircle(
      center, _handleIR,
      Paint()
        ..color = const Color(0x88777777)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Üst-sol yansıma arkı (specular)
    canvas.drawArc(
      Rect.fromCircle(center: center - const Offset(6, 6), radius: _handleOR - 6),
      -math.pi * 0.9, math.pi * 0.45,
      false,
      Paint()
        ..color = const Color(0x44FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // İç delik üst yansıma
    canvas.drawArc(
      Rect.fromCircle(center: center - const Offset(3, 3), radius: _handleIR - 3),
      -math.pi * 0.85, math.pi * 0.40,
      false,
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── Pivot vida ───────────────────────────────────────────────────────────
  void _drawPivotScrew(Canvas canvas, Offset c) {
    const r = 12.0;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Metalik çevre gölgesi
    canvas.drawCircle(
      c + const Offset(2, 3), r + 2,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Vida başı — radyal metalik gradyan
    final screwShader = RadialGradient(
      center: const Alignment(-0.45, -0.45),
      radius: 1.0,
      colors: const [
        Color(0xFFFFFFFF),
        Color(0xFFCCCCCC),
        Color(0xFF888888),
        Color(0xFF444444),
        Color(0xFF111111),
      ],
      stops: const [0.0, 0.15, 0.45, 0.75, 1.0],
    ).createShader(rect);

    canvas.drawCircle(c, r, Paint()..shader = screwShader);

    // Kenar çemberi
    canvas.drawCircle(
      c, r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Çapraz vida yuvası
    final slotPaint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(c + const Offset(-6, -2), c + const Offset(6, 2), slotPaint);
    canvas.drawLine(c + const Offset(-2, -6), c + const Offset(2, 6), slotPaint);

    // Vida yuvası highlight (üst-sol)
    canvas.drawLine(
      c + const Offset(-6, -2), c,
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MetallicScissorsPainter old) =>
      old.spreadAngle != spreadAngle;
}
