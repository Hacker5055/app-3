import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Liquid Glass surface: backdrop-blurred translucent fill with a precise
/// glossy hairline border, floating over the Amoled-black ambient glow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color? fillColor;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
    this.borderColor,
    this.fillColor,
    this.blur = 18,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor ?? FGColors.glassFill,
            borderRadius: br,
            border: Border.all(
              color: borderColor ?? FGColors.glassBorder,
              width: 0.8,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x14FFFFFF), Color(0x05FFFFFF), Color(0x0AFFFFFF)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Ambient glow field behind all glass: absolute black with two extremely
/// subtle radial glows (emerald-safe / crimson-threat reactive light).
class AmbientGlow extends StatelessWidget {
  final Color glowColor;
  const AmbientGlow({super.key, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: FGColors.black),
        child: Stack(
          children: [
            Positioned(
              top: -160,
              right: -100,
              child: _glow(glowColor.withOpacity(0.10), 420),
            ),
            Positioned(
              bottom: -200,
              left: -120,
              child: _glow(const Color(0xFF2B4BFF).withOpacity(0.05), 460),
            ),
            Positioned(
              top: 320,
              left: -180,
              child: _glow(glowColor.withOpacity(0.045), 360),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(Color c, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [c, c.withOpacity(0)]),
      ),
    );
  }
}

/// Small uppercase section header with hairline rule.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 15, color: FGColors.textMid),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: FGTxt.eyebrow),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 0.7, color: FGColors.glassBorderSoft)),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Text(trailing!, style: FGTxt.small),
          ],
        ],
      ),
    );
  }
}

/// Tiny glass pill chip.
class GlassChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  const GlassChip({super.key, required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? FGColors.textMid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: FGColors.glassFill,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: FGColors.glassBorderSoft, width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: c),
            const SizedBox(width: 5),
          ],
          Text(label, style: TextStyle(fontSize: 10.5, color: c, height: 1.2)),
        ],
      ),
    );
  }
}
