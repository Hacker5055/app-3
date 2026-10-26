import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/models.dart';

/// PrivacyFilterService — the privacy & security layer of Footprint Guard.
///
/// Responsibilities:
///  * Classify user input (email / username / phone) locally.
///  * SHA-1 hashing + k-Anonymity prefix/suffix splitting locally, BEFORE
///    any network call. Only the first 5 hex chars ever leave the device
///    for the Pwned Passwords range API.
///  * Redaction for UI chrome, logs and exported report headers.
///  * Zero storage: this service is stateless and writes nothing to disk.
class PrivacyFilterService {
  const PrivacyFilterService();

  static final RegExp _emailRe =
      RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');
  static final RegExp _phoneRe = RegExp(r'^\+?[0-9\s\-()]{7,18}$');
  static final RegExp _usernameRe = RegExp(r'^[A-Za-z0-9._\-]{2,40}$');

  /// Classify raw scanner input.
  InputKind classify(String input) {
    final v = input.trim();
    if (v.isEmpty) return InputKind.unknown;
    if (_emailRe.hasMatch(v)) return InputKind.email;
    final digitsOnly = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (_phoneRe.hasMatch(v) && digitsOnly.length >= 7 && digitsOnly.length <= 15) {
      // A purely numeric string of plausible phone length.
      if (RegExp(r'^[+0-9]').hasMatch(v)) return InputKind.phone;
    }
    if (_usernameRe.hasMatch(v)) return InputKind.username;
    return InputKind.unknown;
  }

  /// Normalize an email (trim + lowercase) per RFC mailbox handling in HIBP.
  String normalizeEmail(String input) => input.trim().toLowerCase();

  /// Normalize a phone number to digits with a leading + if present.
  String normalizePhone(String input) {
    final v = input.trim();
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    return v.startsWith('+') ? '+$digits' : digits;
  }

  /// Extract the probable username handle for OSINT recon.
  ///  * email  -> local part (before @), separators kept
  ///  * username -> as-is (leading @ stripped)
  ///  * phone  -> '' (username recon is not applicable)
  String deriveUsername(String input, InputKind kind) {
    final v = input.trim();
    switch (kind) {
      case InputKind.email:
        return v.split('@').first;
      case InputKind.username:
        return v.startsWith('@') ? v.substring(1) : v;
      case InputKind.phone:
      case InputKind.unknown:
        return '';
    }
  }

  /// SHA-1 hex digest (uppercase, as used by the HIBP range API).
  /// Computed fully on-device.
  String sha1Hex(String value) =>
      sha1.convert(utf8.encode(value)).toString().toUpperCase();

  /// k-Anonymity split: returns (prefix[5], suffix[35]).
  /// ONLY the prefix is transmitted; the suffix is matched locally
  /// against the returned range, so the password (and its full hash)
  /// never leaves the device.
  ({String prefix, String suffix}) kAnonymitySplit(String value) {
    final hash = sha1Hex(value);
    return (prefix: hash.substring(0, 5), suffix: hash.substring(5));
  }

  /// Redact an identifier for display in headers, logs and reports.
  /// a•••@e•••••.com / +20 ••• ••• 1234 / ah•••d
  String redact(String input, InputKind kind) {
    final v = input.trim();
    if (v.isEmpty) return '';
    switch (kind) {
      case InputKind.email:
        final parts = v.split('@');
        if (parts.length != 2) return _maskMiddle(v);
        final local = parts[0];
        final domain = parts[1];
        final shownLocal = local.isEmpty ? '' : local[0];
        final dot = domain.lastIndexOf('.');
        final shownDomain = dot > 0
            ? '${domain[0]}${'•' * 4}${domain.substring(dot)}'
            : '${domain.isEmpty ? '' : domain[0]}${'•' * 4}';
        return '$shownLocal${'•' * 3}@$shownDomain';
      case InputKind.phone:
        final n = normalizePhone(v);
        if (n.length <= 4) return '•••';
        final head = n.startsWith('+') ? n.substring(0, 3) : n.substring(0, 2);
        return '$head ••• ••• ${n.substring(n.length - 4)}';
      case InputKind.username:
        return _maskMiddle(v.startsWith('@') ? v.substring(1) : v);
      case InputKind.unknown:
        return _maskMiddle(v);
    }
  }

  String _maskMiddle(String v) {
    if (v.length <= 2) return '${v.isEmpty ? '' : v[0]}•••';
    return '${v.substring(0, 2)}•••${v[v.length - 1]}';
  }

  /// Basic input sanitation before building URLs (defence in depth).
  String sanitizeForUrl(String username) =>
      username.trim().replaceAll(RegExp(r'[^A-Za-z0-9._\-]'), '');
}
