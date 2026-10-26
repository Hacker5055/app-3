import '../models/models.dart';

/// Social Engineering Threat Calculator.
///
/// Formula (transparent and auditable):
///   Score = clamp( Σ(DataTypeWeight × RecencyFactor)      [per breach, cap 75]
///                + RegisteredPlatformsPenalty             [cap 25]
///                + PwnedPasswordPenalty                   [cap 10]
///                , 0, 100)
///
/// Tiers: Safe 0-20 · Low 21-45 · Moderate 46-70 · Critical 71-100.
class RiskEngine {
  const RiskEngine();

  /// Weight of each leaked data class (HIBP "DataClasses" vocabulary).
  /// Higher = more useful for social engineering / account takeover.
  static const Map<String, double> dataTypeWeights = {
    'Passwords': 18,
    'Password hints': 14,
    'Security questions and answers': 12,
    'Credit cards': 22,
    'Bank account numbers': 22,
    'Social security numbers': 25,
    'Passport numbers': 22,
    'Government issued IDs': 22,
    'Phone numbers': 12,
    'Physical addresses': 14,
    'Dates of birth': 10,
    'IP addresses': 8,
    'Geographic locations': 6,
    'Email addresses': 4,
    'Names': 3,
    'Usernames': 2,
    'Genders': 1,
    'Social media profiles': 3,
    'Private messages': 10,
    'Photos': 6,
    'Employment': 4,
    'Education': 3,
    'Financial': 12,
  };

  static const double breachCap = 75;
  static const double platformCap = 25;
  static const double passwordCap = 10;

  /// Recency factor: fresh leaks are far more weaponizable than stale ones.
  double recencyFactor(DateTime breachDate, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final years = ref.difference(breachDate).inDays / 365.25;
    if (years <= 1) return 1.0;
    if (years <= 3) return 0.85;
    if (years <= 5) return 0.70;
    if (years <= 8) return 0.55;
    return 0.40;
  }

  double weightFor(String dataClass) {
    if (dataTypeWeights.containsKey(dataClass)) return dataTypeWeights[dataClass]!;
    final lower = dataClass.toLowerCase();
    for (final entry in dataTypeWeights.entries) {
      if (lower.contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(lower)) {
        return entry.value;
      }
    }
    return 2; // unknown data classes still carry a small base risk
  }

  RiskAssessment assess({
    required List<Breach> breaches,
    required int registeredPlatforms,
    PwnedPasswordResult? passwordResult,
    DateTime? now,
  }) {
    // --- Breach component -------------------------------------------------
    double breachRaw = 0;
    final perType = <String, List<double>>{}; // dataClass -> contributions
    final perTypeCount = <String, int>{};
    for (final b in breaches) {
      final rf = recencyFactor(b.breachDate, now: now);
      final sensitivityBoost = b.isSensitive ? 1.15 : 1.0;
      for (final dc in b.dataClasses) {
        final contribution = weightFor(dc) * rf * sensitivityBoost;
        breachRaw += contribution;
        (perType[dc] ??= []).add(contribution);
        perTypeCount[dc] = (perTypeCount[dc] ?? 0) + 1;
      }
    }
    final breachComponent = breachRaw > breachCap ? breachCap : breachRaw;

    // --- Registered platforms penalty --------------------------------------
    // 1.5 pts per discovered public account, capped: each public profile is
    // an identity-correlation & pretexting surface for social engineers.
    final platformPenaltyRaw = registeredPlatforms * 1.5;
    final platformPenalty =
        platformPenaltyRaw > platformCap ? platformCap : platformPenaltyRaw;

    // --- Pwned password penalty ---------------------------------------------
    double passwordPenalty = 0;
    if (passwordResult != null && passwordResult.found) {
      passwordPenalty = passwordResult.count > 100000
          ? passwordCap
          : passwordResult.count > 1000
              ? 8
              : 6;
    }

    var score =
        (breachComponent + platformPenalty + passwordPenalty).round();
    if (score < 0) score = 0;
    if (score > 100) score = 100;

    // --- Exposure breakdown (fixed grid order) -------------------------------
    const gridOrder = [
      'Passwords',
      'Email addresses',
      'Phone numbers',
      'IP addresses',
      'Physical addresses',
      'Dates of birth',
      'Credit cards',
      'Social security numbers',
      'Security questions and answers',
      'Names',
      'Usernames',
      'Geographic locations',
    ];
    final breakdown = <ExposureItem>[];
    for (final dc in gridOrder) {
      final contribs = perType[dc] ?? const <double>[];
      breakdown.add(ExposureItem(
        dataClass: dc,
        breachCount: perTypeCount[dc] ?? 0,
        weightedScore:
            contribs.fold<double>(0, (sum, v) => sum + v),
      ));
    }
    // Append any non-standard data classes found in breaches.
    for (final dc in perType.keys) {
      if (!gridOrder.contains(dc)) {
        breakdown.add(ExposureItem(
          dataClass: dc,
          breachCount: perTypeCount[dc] ?? 0,
          weightedScore:
              (perType[dc] ?? const <double>[]).fold<double>(0, (s, v) => s + v),
        ));
      }
    }

    return RiskAssessment(
      score: score,
      tier: tierForScore(score),
      breachComponent: breachComponent,
      platformPenalty: platformPenalty,
      passwordPenalty: passwordPenalty,
      exposureBreakdown: breakdown,
    );
  }
}
