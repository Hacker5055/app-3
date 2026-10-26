import 'package:http/http.dart' as http;

import '../core/privacy_filter_service.dart';
import '../data/platforms.dart';
import '../models/models.dart';

typedef ScanProgress = void Function(int done, int total, PlatformHit hit);

/// OSINTService — username & email recon across 60 mainstream platforms.
///
/// Methodology (WhatsMyName / Holehe-inspired, reimplemented natively):
///  * Each platform defines a public profile URL template plus an existence
///    heuristic: HTTP status, absence marker, or presence marker.
///  * Checks run from the device directly to each platform with bounded
///    concurrency (8 in flight) and a hard per-request timeout.
///  * Only PUBLIC profile pages are requested (GET). No credentials, no
///    posting, no scraping of private data. Results are *indicators* of a
///    registered username — usernames are not unique identities, and each
///    platform carries a reliability rating surfaced in the UI/report.
class OSINTService {
  final http.Client _client;
  final PrivacyFilterService _privacy;

  OSINTService({http.Client? client, PrivacyFilterService? privacy})
      : _client = client ?? http.Client(),
        _privacy = privacy ?? const PrivacyFilterService();

  static const int _concurrency = 8;
  static const Duration _timeout = Duration(seconds: 7);
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14; FootprintGuard/1.0) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/json;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
  };

  /// Check [username] against every platform in the database.
  /// [onProgress] fires after each platform completes (drives the scanner UI).
  Future<List<PlatformHit>> checkUsername(
    String username, {
    List<PlatformDef> platforms = kPlatforms,
    ScanProgress? onProgress,
  }) async {
    final clean = _privacy.sanitizeForUrl(username);
    final results = <PlatformHit>[];
    var done = 0;

    for (var i = 0; i < platforms.length; i += _concurrency) {
      final end =
          (i + _concurrency > platforms.length) ? platforms.length : i + _concurrency;
      final batch = platforms.sublist(i, end);
      final batchResults = await Future.wait(
        batch.map((p) => _checkOne(p, clean)),
      );
      for (final hit in batchResults) {
        results.add(hit);
        done++;
        onProgress?.call(done, platforms.length, hit);
      }
    }
    // Found accounts first, then alphabetical.
    results.sort((a, b) {
      if (a.found != b.found) return a.found ? -1 : 1;
      return a.platform.name.compareTo(b.platform.name);
    });
    return results;
  }

  Future<PlatformHit> _checkOne(PlatformDef platform, String username) async {
    final url = platform.urlFor(username);
    try {
      final res = await _client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);
      final found = evaluate(
        checkType: platform.checkType,
        markers: platform.markers,
        statusCode: res.statusCode,
        body: res.body,
      );
      return PlatformHit(platform: platform, found: found, url: url);
    } catch (_) {
      // Network-blocking (403 challenges, geo-blocks, timeouts) is reported
      // conservatively as "not confirmed" — never as a false positive.
      return PlatformHit(platform: platform, found: false, url: url);
    }
  }

  /// Pure evaluation logic (unit-testable offline).
  static bool evaluate({
    required PlatformCheckType checkType,
    required List<String> markers,
    required int statusCode,
    required String body,
  }) {
    switch (checkType) {
      case PlatformCheckType.status:
        return statusCode >= 200 && statusCode < 300;
      case PlatformCheckType.messageAbsent:
        if (statusCode >= 400) return false;
        final lower = body.toLowerCase();
        return !markers.any((m) => lower.contains(m.toLowerCase()));
      case PlatformCheckType.messagePresent:
        if (statusCode >= 400) return false;
        return markers.any((m) => body.contains(m));
    }
  }

  void close() => _client.close();
}
