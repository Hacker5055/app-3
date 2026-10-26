import 'package:flutter_test/flutter_test.dart';
import 'package:footprint_guard/data/platforms.dart';
import 'package:footprint_guard/services/breach_check_service.dart';
import 'package:footprint_guard/services/osint_service.dart';

void main() {
  group('Pwned Passwords range parsing', () {
    const body = '''
0018A45C4D1DEF81644B54AB7F969B88D65:1
00D4F6E8FA6EECAD2A3AA415EEC418D38EC:2
1E4C9B93F3F0682250B6CF8331B7EE68FD8:9545824
01330C689E5D64F660D6947A93AD634EF8F:0
''';
    test('finds the suffix for sha1(password)', () {
      expect(
        BreachCheckService.parseRangeResponse(
            body, '1E4C9B93F3F0682250B6CF8331B7EE68FD8'),
        9545824,
      );
    });
    test('padding entries (count 0) are ignored', () {
      expect(
        BreachCheckService.parseRangeResponse(
            body, '01330C689E5D64F660D6947A93AD634EF8F'),
        isNull,
      );
    });
    test('absent suffix returns null', () {
      expect(
        BreachCheckService.parseRangeResponse(body, 'FFFFF'),
        isNull,
      );
    });
  });

  group('OSINT existence evaluation', () {
    test('status mode', () {
      expect(
          OSINTService.evaluate(
              checkType: PlatformCheckType.status,
              markers: const [],
              statusCode: 200,
              body: ''),
          isTrue);
      expect(
          OSINTService.evaluate(
              checkType: PlatformCheckType.status,
              markers: const [],
              statusCode: 404,
              body: ''),
          isFalse);
    });
    test('absence-marker mode (case-insensitive)', () {
      expect(
          OSINTService.evaluate(
              checkType: PlatformCheckType.messageAbsent,
              markers: const ['No such user'],
              statusCode: 200,
              body: 'no such USER exists here'),
          isFalse);
      expect(
          OSINTService.evaluate(
              checkType: PlatformCheckType.messageAbsent,
              markers: const ['No such user'],
              statusCode: 200,
              body: 'welcome to the profile'),
          isTrue);
    });
    test('presence-marker mode', () {
      expect(
          OSINTService.evaluate(
              checkType: PlatformCheckType.messagePresent,
              markers: const ['tgme_page_extra'],
              statusCode: 200,
              body: '<div class="tgme_page_extra">@user</div>'),
          isTrue);
    });
  });

  group('platform database integrity', () {
    test('ships 50+ platforms with unique names and valid templates', () {
      expect(kPlatforms.length, greaterThanOrEqualTo(50));
      final names = kPlatforms.map((p) => p.name).toSet();
      expect(names.length, kPlatforms.length);
      for (final p in kPlatforms) {
        expect(p.urlTemplate.contains('{u}'), isTrue, reason: p.name);
        expect(p.urlTemplate.startsWith('https://'), isTrue, reason: p.name);
        expect(p.urlFor('test.user').contains('test.user'), isTrue);
      }
    });
  });
}
