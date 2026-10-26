import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../fg_icons.dart';
import 'glass_card.dart';

/// Full-screen scanner overlay: rotating radar sweep over liquid glass,
/// live stage label, precision progress hairline and a terminal-style log.
class ScannerOverlay extends StatefulWidget {
  final String stage;
  final double progress; // 0..1
  final List<String> logLines;
  final String scanningLabel;

  const ScannerOverlay({
    super.key,
    required this.stage,
    required this.progress,
    required this.logLines,
    required this.scanningLabel,
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.logLines.length > 6
        ? widget.logLines.sublist(widget.logLines.length - 6)
        : widget.logLines;
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: const Color(0xB3000000),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Center(
              child: GlassCard(
                radius: 28,
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                fillColor: const Color(0x1FFFFFFF),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 168,
                      height: 168,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(168, 168),
                            painter: _RadarPainter(animation: _ctrl),
                          ),
                          const Icon(FGI.crosshair,
                              size: 22, color: FGColors.emerald),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.scanningLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                        color: FGColors.emerald,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.stage,
                      textAlign: TextAlign.center,
                      style: FGTxt.body,
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: widget.progress <= 0 ? null : widget.progress,
                        minHeight: 3,
                        backgroundColor: const Color(0x1AFFFFFF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            FGColors.emerald),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${(widget.progress * 100).round()}%',
                        style: FGTxt.mono),
                    if (lines.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x66000000),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: FGColors.glassBorderSoft, width: 0.7),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final l in lines)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 1.5),
                                child: Text(
                                  '> $l',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontFamily: 'monospace',
                                    color: Color(0xFF8FE9C4),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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

class _RadarPainter extends CustomPainter {
  final Animation<double> animation;
  _RadarPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2 - 4;

    // Concentric hairline rings
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0x2EFFFFFF);
    for (final f in [0.36, 0.66, 1.0]) {
      canvas.drawCircle(center, maxR * f, ring);
    }
    // Cross axes
    canvas.drawLine(Offset(center.dx - maxR, center.dy),
        Offset(center.dx + maxR, center.dy), ring);
    canvas.drawLine(Offset(center.dx, center.dy - maxR),
        Offset(center.dx, center.dy + maxR), ring);

    // Rotating sweep (emerald, trailing fade)
    final angle = animation.value * math.pi * 2;
    final rect = Rect.fromCircle(center: center, radius: maxR);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 1.05,
        colors: [
          FGColors.emerald.withOpacity(0.0),
          FGColors.emerald.withOpacity(0.28),
        ],
        transform: GradientRotation(angle - 1.05),
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawArc(rect, angle - 1.05, 1.05, true, sweepPaint);

    // Leading edge line
    canvas.drawLine(
      center,
      center + Offset(math.cos(angle) * maxR, math.sin(angle) * maxR),
      Paint()
        ..strokeWidth = 1.2
        ..color = FGColors.emerald.withOpacity(0.85),
    );

    // Deterministic "blips" that brighten as the sweep passes
    final blips = [
      Offset(center.dx + maxR * 0.42, center.dy - maxR * 0.30),
      Offset(center.dx - maxR * 0.55, center.dy + maxR * 0.22),
      Offset(center.dx + maxR * 0.18, center.dy + maxR * 0.62),
    ];
    for (final b in blips) {
      var a = math.atan2(b.dy - center.dy, b.dx - center.dx);
      if (a < 0) a += math.pi * 2;
      var cur = angle % (math.pi * 2);
      if (cur < 0) cur += math.pi * 2;
      var diff = cur - a;
      if (diff < 0) diff += math.pi * 2;
      final glow = (1 - (diff / (math.pi * 2))).clamp(0.12, 1.0);
      canvas.drawCircle(
        b,
        3.2,
        Paint()..color = FGColors.emerald.withOpacity(glow.toDouble()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
