import '../data/platforms.dart';

/// Footprint Guard — core data models.
///
/// Privacy note: models are held in memory only. Nothing in this file is
/// persisted to disk or transmitted to any custom server.

/// What the user typed into the audit search bar.
enum InputKind { email, username, phone, unknown }

/// Social-engineering threat tiers (score 0-100).
enum ThreatTier { safe, low, moderate, critical }

ThreatTier tierForScore(int score) {
  if (score <= 20) return ThreatTier.safe;
  if (score <= 45) return ThreatTier.low;
  if (score <= 70) return ThreatTier.moderate;
  return ThreatTier.critical;
}

/// A single breach record (mirrors Have I Been Pwned API v3 breach model).
class Breach {
  final String name;
  final String title;
  final String domain;
  final DateTime breachDate;
  final int pwnCount;
  final List<String> dataClasses;
  final bool isVerified;
  final bool isSensitive;
  final String description;

  const Breach({
    required this.name,
    required this.title,
    required this.domain,
    required this.breachDate,
    required this.pwnCount,
    required this.dataClasses,
    this.isVerified = true,
    this.isSensitive = false,
    this.description = '',
  });

  factory Breach.fromHibpJson(Map<String, dynamic> j) {
    return Breach(
      name: (j['Name'] ?? '') as String,
      title: (j['Title'] ?? j['Name'] ?? '') as String,
      domain: (j['Domain'] ?? '') as String,
      breachDate:
          DateTime.tryParse((j['BreachDate'] ?? '') as String) ?? DateTime(2000),
      pwnCount: (j['PwnCount'] ?? 0) as int,
      dataClasses:
          ((j['DataClasses'] as List?) ?? const []).map((e) => e.toString()).toList(),
      isVerified: (j['IsVerified'] ?? false) as bool,
      isSensitive: (j['IsSensitive'] ?? false) as bool,
      description: (j['Description'] ?? '') as String,
    );
  }
}

/// Result of one username existence check against one platform.
class PlatformHit {
  final PlatformDef platform;
  final bool found;
  final String url;
  const PlatformHit({required this.platform, required this.found, required this.url});
}

/// Aggregated exposure for a single leaked data type (e.g. "Passwords").
class ExposureItem {
  final String dataClass;
  final int breachCount;
  final double weightedScore;
  const ExposureItem({
    required this.dataClass,
    required this.breachCount,
    required this.weightedScore,
  });
  bool get exposed => breachCount > 0;
}

/// Remediation priority ordering.
enum RemediationPriority { critical, high, medium, low }

/// One actionable remediation step. Title/body are provided in both
/// languages; the UI resolves them via [titleFor] / [bodyFor].
class RemediationStep {
  final RemediationPriority priority;
  final String iconKey;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final int effortMinutes;

  const RemediationStep({
    required this.priority,
    required this.iconKey,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.effortMinutes,
  });

  String titleFor(bool arabic) => arabic ? titleAr : titleEn;
  String bodyFor(bool arabic) => arabic ? bodyAr : bodyEn;
}

/// Result of the k-Anonymity Pwned Passwords range check.
class PwnedPasswordResult {
  final bool found;
  final int count;
  final String sha1Prefix; // only the 5-char prefix ever leaves the device
  const PwnedPasswordResult({
    required this.found,
    required this.count,
    required this.sha1Prefix,
  });
}

/// Full risk computation output (Social Engineering Threat Calculator).
class RiskAssessment {
  final int score; // 0-100
  final ThreatTier tier;
  final double breachComponent; // sum(weight * recency), capped at 75
  final double platformPenalty; // registered platforms, capped at 25
  final double passwordPenalty; // pwned password, capped at 10
  final List<ExposureItem> exposureBreakdown;

  const RiskAssessment({
    required this.score,
    required this.tier,
    required this.breachComponent,
    required this.platformPenalty,
    required this.passwordPenalty,
    required this.exposureBreakdown,
  });
}

/// Everything one completed audit produced.
class AuditResult {
  final String rawInput;
  final String redactedInput;
  final InputKind inputKind;
  final String lookupUsername;
  final List<Breach> breaches;
  final List<PlatformHit> platformHits;
  final int platformsChecked;
  final RiskAssessment risk;
  final List<RemediationStep> remediation;
  final PwnedPasswordResult? passwordResult;
  final bool mockMode;
  final bool breachLookupSkippedNoKey;
  final DateTime generatedAt;

  const AuditResult({
    required this.rawInput,
    required this.redactedInput,
    required this.inputKind,
    required this.lookupUsername,
    required this.breaches,
    required this.platformHits,
    required this.platformsChecked,
    required this.risk,
    required this.remediation,
    required this.passwordResult,
    required this.mockMode,
    required this.breachLookupSkippedNoKey,
    required this.generatedAt,
  });

  List<PlatformHit> get foundPlatforms =>
      platformHits.where((h) => h.found).toList();
}
