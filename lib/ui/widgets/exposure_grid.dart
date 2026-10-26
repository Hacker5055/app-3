import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../models/models.dart';
import '../../services/risk_engine.dart';
import '../fg_icons.dart';
import 'glass_card.dart';

/// Exposure Breakdown Grid — leaked data types inside glassmorphic cards.
/// Icons stay monochromatic until a leak is detected, then switch to the
/// appropriate warning colour (crimson for high-weaponization types).
class ExposureGrid extends StatelessWidget {
  final List<ExposureItem> items;
  final S s;
  const ExposureGrid({super.key, required this.items, required this.s});

  Color _colorFor(ExposureItem e) {
    if (!e.exposed) return FGColors.textLow;
    final w = RiskEngine.dataTypeWeights[e.dataClass] ?? 2;
    if (w >= 12) return FGColors.crimson;
    if (w >= 6) return FGColors.amber;
    return const Color(0xFF7BE8B8);
  }

  @override
  Widget build(BuildContext context) {
    final shown = items.take(9).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.94,
      ),
      itemCount: shown.length,
      itemBuilder: (context, i) {
        final e = shown[i];
        final c = _colorFor(e);
        return GlassCard(
          radius: 18,
          padding: const EdgeInsets.all(12),
          borderColor:
              e.exposed ? c.withOpacity(0.38) : FGColors.glassBorderSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Icon(FGI.forDataClass(e.dataClass), size: 20, color: c),
                  if (e.exposed)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: c.withOpacity(0.7), blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                s.dataClassLabel(e.dataClass),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: FGColors.textHi,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                e.exposed
                    ? '${s.exposed} · ${e.breachCount} ${s.breaches}'
                    : s.notExposed,
                style: TextStyle(fontSize: 9.5, color: c, height: 1.2),
              ),
            ],
          ),
        );
      },
    );
  }
}
