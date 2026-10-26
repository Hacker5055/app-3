import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/privacy_filter_service.dart';
import '../models/models.dart';

typedef ScanLog = void Function(String message);

/// BreachCheckService — Have I Been Pwned integration wrappers.
///
/// Two distinct privacy models, handled honestly and separately:
///  1. Pwned Passwords (range API): pure k-Anonymity. Only the first 5
///     chars of the local SHA-1 hash are sent; matching happens on-device.
///     No API key required.
///  2. Breached-account (API v3): the official API requires the account
///     identifier + a personal API key. The request goes directly from
///     this device to haveibeenpwned.com over TLS — Footprint Guard has
///     NO backend and never proxies, logs or stores the identifier.
///     The key is supplied at build time (--dart-define=HIBP_API_KEY=...)
///     or pasted in-app and kept in memory only.
class BreachCheckService {
  final http.Client _client;
  final PrivacyFilterService _privacy;

  BreachCheckService({http.Client? client, PrivacyFilterService? privacy})
      : _client = client ?? http.Client(),
        _privacy = privacy ?? const PrivacyFilterService();

  static const String _rangeBase = 'https://api.pwnedpasswords.com/range/';
  static const String _hibpBase = 'https://haveibeenpwned.com/api/v3';
  static const String _userAgent = 'FootprintGuard/1.0 (Android; OSINT Audit)';

  /// k-Anonymity password check.
  ///
  /// GET https://api.pwnedpasswords.com/range/{FIRST_5_OF_SHA1}
  /// with `Add-Padding: true` so response sizes are uniform (~1 padding
  /// bucket), then the 35-char suffix is matched LOCALLY.
  Future<PwnedPasswordResult> checkPasswordPwned(
    String password, {
    ScanLog? log,
  }) async {
    final split = _privacy.kAnonymitySplit(password);
    log?.call('k-Anonymity: SHA-1 computed locally, sending prefix '
        '${split.prefix} only');
    final res = await _client
        .get(
          Uri.parse('$_rangeBase${split.prefix}'),
          headers: {'User-Agent': _userAgent, 'Add-Padding': 'true'},
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw BreachLookupException(
          'Pwned Passwords range API returned HTTP ${res.statusCode}');
    }
    final result = parseRangeResponse(res.body, split.suffix);
    return PwnedPasswordResult(
      found: result != null,
      count: result ?? 0,
      sha1Prefix: split.prefix,
    );
  }

  /// Parse a range API body (`SUFFIX:COUNT` per line). Returns the sighting
  /// count if [suffix] is present, otherwise null. Padding entries have a
  /// count of 0 and are ignored. Pure function — unit-testable offline.
  static int? parseRangeResponse(String body, String suffix) {
    final target = suffix.toUpperCase();
    for (final line in const LineSplitter().convert(body)) {
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final s = line.substring(0, idx).trim().toUpperCase();
      if (s == target) {
        final count = int.tryParse(line.substring(idx + 1).trim()) ?? 0;
        return count > 0 ? count : null;
      }
    }
    return null;
  }

  /// HIBP API v3 breached-account lookup for an email address.
  /// Requires a personal HIBP API key (https://haveibeenpwned.com/API/Key).
  /// HTTP 404 means "not found in any breach" and yields an empty list.
  Future<List<Breach>> checkEmailBreaches(
    String email, {
    required String apiKey,
    ScanLog? log,
  }) async {
    final account = Uri.encodeComponent(_privacy.normalizeEmail(email));
    final uri = Uri.parse(
        '$_hibpBase/breachedaccount/$account?truncateResponse=false');
    log?.call('HIBP v3: direct TLS request device -> haveibeenpwned.com '
        '(no intermediary servers)');
    final res = await _client.get(uri, headers: {
      'hibp-api-key': apiKey,
      'User-Agent': _userAgent,
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 15));

    if (res.statusCode == 404) return <Breach>[];
    if (res.statusCode == 401) {
      throw const BreachLookupException(
          'HIBP rejected the API key (HTTP 401). Verify your key.');
    }
    if (res.statusCode == 429) {
      throw const BreachLookupException(
          'HIBP rate limit reached (HTTP 429). Wait a moment and retry.');
    }
    if (res.statusCode != 200) {
      throw BreachLookupException('HIBP returned HTTP ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return <Breach>[];
    final breaches = decoded
        .whereType<Map<String, dynamic>>()
        .map(Breach.fromHibpJson)
        .toList();
    breaches.sort((a, b) => b.breachDate.compareTo(a.breachDate));
    return breaches;
  }

  void close() => _client.close();
}

class BreachLookupException implements Exception {
  final String message;
  const BreachLookupException(this.message);
  @override
  String toString() => message;
}
