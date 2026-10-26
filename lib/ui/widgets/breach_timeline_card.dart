import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../models/models.dart';
import '../fg_icons.dart';
import 'glass_card.dart';

String _fmtNum(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Elegant vertical breach-history timeline inside one transparent liquid
/// glass container. Precise dates, minimalist threat icons, no clutter.
class BreachTimeline extends StatelessWidget {
  final List<Breach> breaches;
  final S s;
  const BreachTimeline({super.key, required this.breaches, required this.s});

  @override
  Widget build(BuildContext context) {
    if (breaches.isEmpty) {
      return GlassCard(
        child: Row(
          children: [
            const Icon(FGI.checkCircle, size: 18, color: FGColors.emerald),
            const SizedBox(width: 10),
            Expanded(child: Text(s.notPwned, style: FGTxt.body)),
          ],
        ),
      );
    }
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        children: [
          for (var i = 0; i < breaches.length; i++)
            BreachTimelineCard(
              breach: breaches[i],
              s: s,
              isLast: i == breaches.length - 1,
            ),
        ],
      ),
    );
  }
}

/// One event on the breach timeline.
class BreachTimelineCard extends StatelessWidget {
  final Breach breach;
  final S s;
  final bool isLast;
  const BreachTimelineCard({
    super.key,
    required this.breach,
    required this.s,
    required this.isLast,
  });

  Color get _dotColor {
    if (breach.isSensitive) return FGColors.crimson;
    if (breach.dataClasses.contains('Passwords')) return FGColors.crimson;
    if (breach.dataClasses.contains('Phone numbers')) return FGColors.amber;
    return FGColors.textMid;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FGColors.black,
                    border: Border.all(color: _dotColor, width: 1.6),
                    boxShadow: [
                      BoxShadow(
                          color: _dotColor.withOpacity(0.45), blurRadius: 7),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 0.8,
                      color: FGColors.glassBorder,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 10 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          breach.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: FGColors.textHi,
                          ),
                        ),
                      ),
                      GlassChip(
                        label: _fmtDate(breach.breachDate),
                        icon: FGI.calendar,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (breach.domain.isNotEmpty)
                        GlassChip(label: breach.domain, icon: FGI.globe),
                      GlassChip(
                        label:
                            '${_fmtNum(breach.pwnCount)} ${s.accountsAffected}',
                        icon: FGI.users,
                      ),
                      GlassChip(
                        label: breach.isVerified ? s.verified : s.unverified,
                        icon: breach.isVerified ? FGI.checkCircle : FGI.info,
                        color: breach.isVerified
                            ? FGColors.emeraldDim
                            : FGColors.textLow,
                      ),
                      if (breach.isSensitive)
                        GlassChip(
                          label: s.sensitive,
                          icon: FGI.alertTriangle,
                          color: FGColors.crimson,
                        ),
                    ],
                  ),
                  if (breach.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      breach.description
                          .replaceAll(RegExp(r'<[^>]*>'), ''),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: FGTxt.small,
                    ),
                  ],
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final dc in breach.dataClasses)
                        GlassChip(
                          label: s.dataClassLabel(dc),
                          icon: FGI.forDataClass(dc),
                          color: (dc == 'Passwords' ||
                                  dc == 'Credit cards' ||
                                  dc == 'Social security numbers')
                              ? FGColors.crimson
                              : FGColors.textMid,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
