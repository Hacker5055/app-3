import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/models.dart';

/// RiskGaugeWidget — radar-style exposure gauge with precise, clean
/// geometry: 270° graduated arc, hairline ticks, muted reactive gradient
/// (emerald -> amber -> crimson) and a glowing terminator dot.
class RiskGaugeWidget extends StatelessWidget {
  final int score; // 0-100
  final ThreatTier tier;
  final String tierLabel;
  final String caption;
  final double size;

  const RiskGaugeWidget({
    super.key,
    required this.score,
    required this.tier,
    required this.tierLabel,
    required this.caption,
    this.size = 248,
  });

  Color get _tierColor => FGColors.tierColorName(tier.name);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _GaugePainter(value: value, tierColor: _tierColor),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${value.round()}',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w200,
                            color: FGColors.textHi,
                            height: 1,
                          ),
                        ),
                        const TextSpan(
                          text: ' /100',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            color: FGColors.textLow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tierColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(99),
                      border:
                          Border.all(color: _tierColor.withOpacity(0.45), width: 0.8),
                    ),
                    child: Text(
                      tierLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w600,
                        color: _tierColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(caption, style: FGTxt.small),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color tierColor;
  const _GaugePainter({required this.value, required this.tierColor});

  static const double _start = math.pi * 0.75; // 135°
  static const double _sweep = math.pi * 1.5; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 22;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x14FFFFFF);
    canvas.drawArc(rect, _start, _sweep, false, track);

    // Graduated hairline ticks (0..100, minor every 5, major every 25)
    final minor = Paint()
      ..strokeWidth = 0.8
      ..color = const Color(0x33FFFFFF);
    final major = Paint()
      ..strokeWidth = 1.1
      ..color = const Color(0x59FFFFFF);
    for (var i = 0; i <= 20; i++) {
      final a = _start + _sweep * (i / 20);
      final isMajor = i % 5 == 0;
      final r1 = radius + 11;
      final r2 = radius + (isMajor ? 19 : 15);
      canvas.drawLine(
        center + Offset(math.cos(a) * r1, math.sin(a) * r1),
        center + Offset(math.cos(a) * r2, math.sin(a) * r2),
        isMajor ? major : minor,
      );
      if (isMajor) {
        final label = '${i * 5}';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontSize: 8.5, color: FGColors.textLow),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final pos = center +
            Offset(math.cos(a) * (radius + 30), math.sin(a) * (radius + 30));
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Tier threshold separators at 20 / 45 / 70
    final sep = Paint()
      ..strokeWidth = 1.4
      ..color = const Color(0xFF000000);
    for (final t in [20, 45, 70]) {
      final a = _start + _sweep * (t / 100);
      canvas.drawLine(
        center + Offset(math.cos(a) * (radius - 6), math.sin(a) * (radius - 6)),
        center + Offset(math.cos(a) * (radius + 6), math.sin(a) * (radius + 6)),
        sep,
      );
    }

    // Value arc with reactive muted gradient
    final frac = (value / 100).clamp(0.0, 1.0);
    if (frac > 0) {
      final shader = const SweepGradient(
        startAngle: 0,
        endAngle: _sweep,
        colors: [
          FGColors.emerald,
          Color(0xFF5FE3B0),
          FGColors.amber,
          FGColors.orangeDeep,
          FGColors.crimson,
        ],
        stops: [0.0, 0.32, 0.55, 0.78, 1.0],
        transform: GradientRotation(_start),
      ).createShader(rect);
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..shader = shader;
      canvas.drawArc(rect, _start, _sweep * frac, false, arcPaint);

      // Glowing terminator dot
      final endA = _start + _sweep * frac;
      final endPos =
          center + Offset(math.cos(endA) * radius, math.sin(endA) * radius);
      final glow = Paint()
        ..color = tierColor.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(endPos, 10, glow);
      canvas.drawCircle(endPos, 4.2, Paint()..color = tierColor);
      canvas.drawCircle(
        endPos,
        4.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xCCFFFFFF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.tierColor != tierColor;
}
