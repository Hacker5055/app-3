import 'package:flutter/foundation.dart';

import '../core/privacy_filter_service.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/breach_check_service.dart';
import '../services/mock_data.dart';
import '../services/osint_service.dart';
import '../services/remediation_engine.dart';
import '../services/report_export_service.dart';
import '../services/risk_engine.dart';

/// Compile-time HIBP key: flutter build apk --dart-define=HIBP_API_KEY=xxxx
const String _envHibpKey = String.fromEnvironment('HIBP_API_KEY');

/// AuditController — single source of truth for the audit state machine.
///
/// Pipeline: classify -> breach lookup -> platform sweep -> threat scoring
/// -> remediation plan. All sensitive values live in memory only and are
/// discarded on reset. Nothing is persisted, ever.
class AuditController extends ChangeNotifier {
  final PrivacyFilterService privacy = const PrivacyFilterService();
  final BreachCheckService breachService = BreachCheckService();
  final OSINTService osintService = OSINTService();
  final RiskEngine riskEngine = const RiskEngine();
  final RemediationEngine remediationEngine = const RemediationEngine();
  final MockData mock = const MockData();
  final ReportExportService reports = const ReportExportService();

  bool arabic = true; // Arabic-first product; EN toggle in header
  bool mockMode = true; // Mock Audit Mode ON by default (emulator-friendly)
  String hibpApiKey = _envHibpKey; // memory only

  bool isScanning = false;
  bool passwordBusy = false;
  int stageIndex = 0;
  double progress = 0;
  final List<String> logLines = [];
  AuditResult? result;
  PwnedPasswordResult? standalonePasswordResult;
  String? error;

  S get s => S(arabic);
  bool get hasKey => hibpApiKey.trim().isNotEmpty;

  String get stageLabel {
    switch (stageIndex) {
      case 0:
        return s.stageClassify;
      case 1:
        return s.stageBreaches;
      case 2:
        return s.stagePlatforms;
      case 3:
        return s.stageRisk;
      default:
        return s.stagePlan;
    }
  }

  void toggleLanguage() {
    arabic = !arabic;
    notifyListeners();
  }

  void setMockMode(bool v) {
    mockMode = v;
    notifyListeners();
  }

  void setHibpKey(String v) {
    hibpApiKey = v.trim();
    notifyListeners();
  }

  void reset() {
    result = null;
    error = null;
    logLines.clear();
    progress = 0;
    stageIndex = 0;
    notifyListeners();
  }

  void _log(String line) {
    logLines.add(line);
    if (logLines.length > 80) logLines.removeAt(0);
  }

  void _setStage(int i, double p) {
    stageIndex = i;
    progress = p;
    notifyListeners();
  }

  Future<void> runAudit(String rawInput, {String? passwordToCheck}) async {
    final input = rawInput.trim();
    if (input.isEmpty || isScanning) return;
    error = null;
    logLines.clear();
    isScanning = true;
    progress = 0;
    notifyListeners();

    try {
      // ---- Stage 0: classify + privacy filter ------------------------------
      _setStage(0, 0.05);
      final kind = privacy.classify(input);
      if (kind == InputKind.unknown) {
        throw AuditException(s.unknownInput);
      }
      final username = privacy.deriveUsername(input, kind);
      final redacted = privacy.redact(input, kind);
      final localHash = privacy.sha1Hex(input.toLowerCase());
      _log('input classified: ${kind.name}');
      _log('SHA-1 local digest armed: ${localHash.substring(0, 5)}'
          '${'*' * 35} (suffix never transmitted)');
      _log('redacted identity: $redacted');
      await _pause(mockMode ? 650 : 120);

      // ---- Optional k-Anonymity password check ------------------------------
      PwnedPasswordResult? pwResult;
      if (passwordToCheck != null && passwordToCheck.isNotEmpty) {
        pwResult = await _checkPasswordInternal(passwordToCheck);
      }

      // ---- Stage 1: breach lookup -------------------------------------------
      _setStage(1, 0.22);
      var breaches = <Breach>[];
      var skippedNoKey = false;
      if (mockMode) {
        _log('MOCK: simulating breach corpora query');
        await _pause(900);
        breaches = mock.breachesFor(input, kind);
        _log('MOCK: ${breaches.length} simulated breach records matched');
      } else if (kind == InputKind.email) {
        if (hasKey) {
          breaches = await breachService.checkEmailBreaches(
            input,
            apiKey: hibpApiKey,
            log: _log,
          );
          _log('HIBP v3: ${breaches.length} breach records returned');
        } else {
          skippedNoKey = true;
          _log('HIBP v3 skipped: no API key configured');
        }
      } else {
        _log('breach corpus lookup requires an email input; '
            'continuing with recon + scoring');
      }

      // ---- Stage 2: platform sweep -------------------------------------------
      _setStage(2, 0.34);
      var hits = <PlatformHit>[];
      if (username.isNotEmpty) {
        if (mockMode) {
          hits = await _mockSweep(input, username);
        } else {
          hits = await osintService.checkUsername(
            username,
            onProgress: (done, total, hit) {
              progress = 0.34 + (done / total) * 0.5;
              if (hit.found) _log('FOUND ${hit.platform.name} -> ${hit.url}');
              notifyListeners();
            },
          );
        }
      } else {
        _log('phone input: username recon not applicable');
      }

      // ---- Stage 3: threat scoring --------------------------------------------
      _setStage(3, 0.9);
      await _pause(mockMode ? 450 : 60);
      final foundCount = hits.where((h) => h.found).length;
      final risk = riskEngine.assess(
        breaches: breaches,
        registeredPlatforms: foundCount,
        passwordResult: pwResult,
      );
      _log('score = ${risk.score} '
          '(breach ${risk.breachComponent.toStringAsFixed(1)} + '
          'platforms ${risk.platformPenalty.toStringAsFixed(1)} + '
          'password ${risk.passwordPenalty.toStringAsFixed(1)})');

      // ---- Stage 4: remediation ------------------------------------------------
      _setStage(4, 0.97);
      await _pause(mockMode ? 400 : 40);
      final plan = remediationEngine.buildPlan(
        breaches: breaches,
        platformHits: hits,
        passwordResult: pwResult,
        risk: risk,
        inputKind: kind,
      );

      result = AuditResult(
        rawInput: input,
        redactedInput: redacted,
        inputKind: kind,
        lookupUsername: username,
        breaches: breaches,
        platformHits: hits,
        platformsChecked: hits.length,
        risk: risk,
        remediation: plan,
        passwordResult: pwResult,
        mockMode: mockMode,
        breachLookupSkippedNoKey: skippedNoKey,
        generatedAt: DateTime.now(),
      );
      progress = 1;
    } on AuditException catch (e) {
      error = e.message;
    } catch (e) {
      error = '${s.errorGeneric}: $e';
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  /// Simulated platform sweep with realistic pacing for the scanner UI.
  Future<List<PlatformHit>> _mockSweep(String input, String username) async {
    final all = mock.platformsFor(input, username);
    final total = all.length;
    for (var i = 0; i < total; i += 4) {
      progress = 0.34 + ((i + 4).clamp(0, total) / total) * 0.5;
      for (var j = i; j < (i + 4).clamp(0, total); j++) {
        if (all[j].found) _log('FOUND ${all[j].platform.name} -> ${all[j].url}');
      }
      notifyListeners();
      await _pause(85);
    }
    return all;
  }

  /// Standalone password check from the password card. If an audit result
  /// already exists, the threat score is recomputed with the new penalty.
  Future<void> checkPassword(String password) async {
    if (password.isEmpty || passwordBusy) return;
    passwordBusy = true;
    error = null;
    notifyListeners();
    try {
      final r = await _checkPasswordInternal(password);
      standalonePasswordResult = r;
      final current = result;
      if (current != null) {
        final risk = riskEngine.assess(
          breaches: current.breaches,
          registeredPlatforms: current.foundPlatforms.length,
          passwordResult: r,
        );
        result = AuditResult(
          rawInput: current.rawInput,
          redactedInput: current.redactedInput,
          inputKind: current.inputKind,
          lookupUsername: current.lookupUsername,
          breaches: current.breaches,
          platformHits: current.platformHits,
          platformsChecked: current.platformsChecked,
          risk: risk,
          remediation: remediationEngine.buildPlan(
            breaches: current.breaches,
            platformHits: current.platformHits,
            passwordResult: r,
            risk: risk,
            inputKind: current.inputKind,
          ),
          passwordResult: r,
          mockMode: current.mockMode,
          breachLookupSkippedNoKey: current.breachLookupSkippedNoKey,
          generatedAt: current.generatedAt,
        );
      }
    } catch (e) {
      error = '$e';
    } finally {
      passwordBusy = false;
      notifyListeners();
    }
  }

  Future<PwnedPasswordResult> _checkPasswordInternal(String password) async {
    final split = privacy.kAnonymitySplit(password);
    _log('k-Anonymity: prefix ${split.prefix} leaves device; '
        'suffix matched locally');
    if (mockMode) {
      await _pause(750);
      return mock.passwordFor(password, split.prefix);
    }
    return breachService.checkPasswordPwned(password, log: _log);
  }

  Future<void> _pause(int ms) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  @override
  void dispose() {
    breachService.close();
    osintService.close();
    super.dispose();
  }
}

class AuditException implements Exception {
  final String message;
  const AuditException(this.message);
  @override
  String toString() => message;
}
