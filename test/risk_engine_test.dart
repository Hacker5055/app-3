import 'package:flutter_test/flutter_test.dart';
import 'package:footprint_guard/models/models.dart';
import 'package:footprint_guard/services/risk_engine.dart';

Breach _b(String name, DateTime date, List<String> dc,
        {bool sensitive = false}) =>
    Breach(
      name: name,
      title: name,
      domain: '',
      breachDate: date,
      pwnCount: 1000,
      dataClasses: dc,
      isSensitive: sensitive,
    );

void main() {
  const engine = RiskEngine();
  final now = DateTime(2025, 1, 1);

  group('threat tiers', () {
    test('boundaries 0-20 / 21-45 / 46-70 / 71-100', () {
      expect(tierForScore(0), ThreatTier.safe);
      expect(tierForScore(20), ThreatTier.safe);
      expect(tierForScore(21), ThreatTier.low);
      expect(tierForScore(45), ThreatTier.low);
      expect(tierForScore(46), ThreatTier.moderate);
      expect(tierForScore(70), ThreatTier.moderate);
      expect(tierForScore(71), ThreatTier.critical);
      expect(tierForScore(100), ThreatTier.critical);
    });
  });

  group('recency factor', () {
    test('decays with age', () {
      expect(engine.recencyFactor(DateTime(2024, 6, 1), now: now), 1.0);
      expect(engine.recencyFactor(DateTime(2023, 1, 1), now: now), 0.85);
      expect(engine.recencyFactor(DateTime(2021, 1, 1), now: now), 0.70);
      expect(engine.recencyFactor(DateTime(2018, 1, 1), now: now), 0.55);
      expect(engine.recencyFactor(DateTime(2010, 1, 1), now: now), 0.40);
    });
  });

  group('score formula', () {
    test('clean identity scores 0 / safe', () {
      final r = engine.assess(
          breaches: const [], registeredPlatforms: 0, now: now);
      expect(r.score, 0);
      expect(r.tier, ThreatTier.safe);
    });

    test('single fresh Adobe-style breach: (18+14+4+2) x 1.0 = 38', () {
      final r = engine.assess(
        breaches: [
          _b('AdobeLike', DateTime(2024, 6, 1),
              ['Passwords', 'Password hints', 'Email addresses', 'Usernames'])
        ],
        registeredPlatforms: 0,
        now: now,
      );
      expect(r.breachComponent, closeTo(38.0, 0.001));
      expect(r.score, 38);
      expect(r.tier, ThreatTier.low);
    });

    test('platform penalty: 1.5 each, capped at 25', () {
      final r10 = engine.assess(
          breaches: const [], registeredPlatforms: 10, now: now);
      expect(r10.platformPenalty, 15.0);
      final r40 = engine.assess(
          breaches: const [], registeredPlatforms: 40, now: now);
      expect(r40.platformPenalty, 25.0);
    });

    test('breach component caps at 75 and score at 100', () {
      final many = List.generate(
        12,
        (i) => _b('B$i', DateTime(2024, 6, 1),
            ['Passwords', 'Credit cards', 'Phone numbers']),
      );
      final r = engine.assess(
        breaches: many,
        registeredPlatforms: 30,
        passwordResult: const PwnedPasswordResult(
            found: true, count: 500000, sha1Prefix: 'ABCDE'),
        now: now,
      );
      expect(r.breachComponent, 75.0);
      expect(r.platformPenalty, 25.0);
      expect(r.passwordPenalty, 10.0);
      expect(r.score, 100);
      expect(r.tier, ThreatTier.critical);
    });

    test('sensitive breach boost x1.15', () {
      final r = engine.assess(
        breaches: [
          _b('S', DateTime(2024, 6, 1), ['Passwords'], sensitive: true)
        ],
        registeredPlatforms: 0,
        now: now,
      );
      expect(r.breachComponent, closeTo(18 * 1.15, 0.001));
    });

    test('exposure breakdown counts per data class', () {
      final r = engine.assess(
        breaches: [
          _b('A', DateTime(2024, 6, 1), ['Passwords']),
          _b('B', DateTime(2024, 6, 1), ['Passwords', 'Phone numbers']),
        ],
        registeredPlatforms: 0,
        now: now,
      );
      final pw = r.exposureBreakdown.firstWhere((e) => e.dataClass == 'Passwords');
      final ph =
          r.exposureBreakdown.firstWhere((e) => e.dataClass == 'Phone numbers');
      final cc =
          r.exposureBreakdown.firstWhere((e) => e.dataClass == 'Credit cards');
      expect(pw.breachCount, 2);
      expect(ph.breachCount, 1);
      expect(cc.exposed, isFalse);
    });
  });
}
