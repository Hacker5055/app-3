import 'package:flutter_test/flutter_test.dart';
import 'package:footprint_guard/core/privacy_filter_service.dart';
import 'package:footprint_guard/models/models.dart';

void main() {
  const privacy = PrivacyFilterService();

  group('input classification', () {
    test('email', () {
      expect(privacy.classify('user@example.com'), InputKind.email);
      expect(privacy.classify('  User.Name+tag@Example.CO '), InputKind.email);
    });
    test('phone', () {
      expect(privacy.classify('+20 100 123 4567'), InputKind.phone);
      expect(privacy.classify('+1 (555) 010-2030'), InputKind.phone);
    });
    test('username', () {
      expect(privacy.classify('ahmed.sec_01'), InputKind.username);
      expect(privacy.classify('0xResearcher'), InputKind.username);
    });
    test('unknown', () {
      expect(privacy.classify(''), InputKind.unknown);
      expect(privacy.classify('bad input with spaces!'), InputKind.unknown);
    });
  });

  group('k-Anonymity SHA-1 (known HIBP vector)', () {
    test('sha1(password) matches the public HIBP example', () {
      expect(privacy.sha1Hex('password'),
          '5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8');
    });
    test('split yields 5-char prefix + 35-char suffix', () {
      final s = privacy.kAnonymitySplit('password');
      expect(s.prefix, '5BAA6');
      expect(s.suffix, '1E4C9B93F3F0682250B6CF8331B7EE68FD8');
      expect(s.suffix.length, 35);
    });
  });

  group('derivation + redaction', () {
    test('email local part becomes the OSINT username', () {
      expect(privacy.deriveUsername('ahmed.sec@example.com', InputKind.email),
          'ahmed.sec');
    });
    test('phone has no username', () {
      expect(privacy.deriveUsername('+201001234567', InputKind.phone), '');
    });
    test('redaction never leaks the full identifier', () {
      final r = privacy.redact('secret.name@example.com', InputKind.email);
      expect(r.contains('secret'), isFalse);
      expect(r.contains('@'), isTrue);
      expect(r.endsWith('.com'), isTrue);
      final p = privacy.redact('+201001234567', InputKind.phone);
      expect(p.contains('100123'), isFalse);
      expect(p.endsWith('4567'), isTrue);
    });
  });
}
