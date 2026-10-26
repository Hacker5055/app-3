import 'dart:math';

import '../data/platforms.dart';
import '../models/models.dart';

/// Mock Audit Mode data.
///
/// Generates a DETERMINISTIC, per-input simulated audit so the full UX —
/// scanner animation, risk gauge, breach timeline, remediation plan and
/// report export — can be exercised in an emulator with no API keys and
/// no network. Breach records below use public, factual metadata of
/// well-known historical breaches (names, dates, sizes, data classes)
/// purely as realistic fixtures; in Mock Mode the app never claims the
/// audited identity was actually in them. Every mock surface is badged
/// "SIMULATED" in the UI and in exported reports.
class MockData {
  const MockData();

  static int _seedFor(String input) {
    var h = 0;
    for (final c in input.toLowerCase().codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h == 0 ? 42 : h;
  }

  /// Fictionalized assignment of real breach metadata for simulation.
  List<Breach> breachesFor(String input, InputKind kind) {
    final rng = Random(_seedFor(input));
    final pool = List<Breach>.from(_breachPool)..shuffle(rng);
    // Phone audits: fewer (phone-centric) corpora in the simulation.
    final count = kind == InputKind.phone
        ? 1 + rng.nextInt(2)
        : 3 + rng.nextInt(4); // 3-6
    final picked = pool.take(count).toList()
      ..sort((a, b) => b.breachDate.compareTo(a.breachDate));
    return picked;
  }

  List<PlatformHit> platformsFor(String input, String username) {
    final rng = Random(_seedFor('$input#platforms'));
    final idx = List<int>.generate(kPlatforms.length, (i) => i)..shuffle(rng);
    final foundCount = 6 + rng.nextInt(11); // 6-16 registered platforms
    final foundIdx = idx.take(foundCount).toSet();
    final hits = <PlatformHit>[];
    for (var i = 0; i < kPlatforms.length; i++) {
      final p = kPlatforms[i];
      hits.add(PlatformHit(
        platform: p,
        found: foundIdx.contains(i),
        url: p.urlFor(username.isEmpty ? 'user' : username),
      ));
    }
    hits.sort((a, b) {
      if (a.found != b.found) return a.found ? -1 : 1;
      return a.platform.name.compareTo(b.platform.name);
    });
    return hits;
  }

  PwnedPasswordResult passwordFor(String password, String prefix) {
    final weak = password.length < 10 ||
        RegExp(r'^[0-9]+$').hasMatch(password) ||
        _common.contains(password.toLowerCase());
    if (!weak) {
      return PwnedPasswordResult(found: false, count: 0, sha1Prefix: prefix);
    }
    final rng = Random(_seedFor(password));
    return PwnedPasswordResult(
      found: true,
      count: 1200 + rng.nextInt(9000000),
      sha1Prefix: prefix,
    );
  }

  static const _common = {
    'password', '123456', '12345678', 'qwerty', 'letmein', 'admin', '111111',
    '123456789', '12345', '123123', 'password1', 'iloveyou',
  };

  static List<Breach> get _breachPool => [
        Breach(
          name: 'Adobe',
          title: 'Adobe',
          domain: 'adobe.com',
          breachDate: DateTime(2013, 10, 4),
          pwnCount: 152445165,
          dataClasses: const [
            'Email addresses', 'Password hints', 'Passwords', 'Usernames'
          ],
          description:
              'In October 2013, 153 million Adobe accounts were breached with encrypted passwords and plain-text password hints.',
        ),
        Breach(
          name: 'LinkedIn',
          title: 'LinkedIn',
          domain: 'linkedin.com',
          breachDate: DateTime(2012, 5, 5),
          pwnCount: 164611595,
          dataClasses: const ['Email addresses', 'Passwords'],
          description:
              'In 2012 LinkedIn was breached; 164 million email addresses and unsalted SHA-1 password hashes later surfaced for sale.',
        ),
        Breach(
          name: 'Canva',
          title: 'Canva',
          domain: 'canva.com',
          breachDate: DateTime(2019, 5, 24),
          pwnCount: 137272116,
          dataClasses: const [
            'Email addresses', 'Geographic locations', 'Names', 'Passwords',
            'Usernames'
          ],
          description:
              'In May 2019 the graphic design service Canva suffered a breach of 137 million subscribers including bcrypt-hashed passwords.',
        ),
        Breach(
          name: 'Dubsmash',
          title: 'Dubsmash',
          domain: 'dubsmash.com',
          breachDate: DateTime(2018, 12, 1),
          pwnCount: 161749950,
          dataClasses: const ['Email addresses', 'Passwords', 'Usernames'],
          description:
              'In December 2018, 162 million Dubsmash accounts were breached and later sold on a dark web marketplace.',
        ),
        Breach(
          name: 'MyFitnessPal',
          title: 'MyFitnessPal',
          domain: 'myfitnesspal.com',
          breachDate: DateTime(2018, 2, 1),
          pwnCount: 143606147,
          dataClasses: const ['Email addresses', 'IP addresses', 'Passwords'],
          description:
              'In February 2018, 144 million MyFitnessPal accounts were breached and sold online the following year.',
        ),
        Breach(
          name: 'Twitter2022',
          title: 'Twitter (2022 API scrape)',
          domain: 'twitter.com',
          breachDate: DateTime(2022, 1, 1),
          pwnCount: 211524284,
          dataClasses: const ['Email addresses', 'Names', 'Phone numbers', 'Usernames'],
          description:
              'An API vulnerability allowed enumeration linking email addresses and phone numbers to Twitter accounts; 211 million records circulated in 2023.',
        ),
        Breach(
          name: 'Wattpad',
          title: 'Wattpad',
          domain: 'wattpad.com',
          breachDate: DateTime(2020, 6, 29),
          pwnCount: 268765495,
          dataClasses: const [
            'Dates of birth', 'Email addresses', 'Genders', 'Geographic locations',
            'IP addresses', 'Names', 'Passwords', 'Social media profiles',
            'Usernames'
          ],
          description:
              'In June 2020 the user-generated stories website Wattpad suffered a breach exposing 269 million records.',
        ),
        Breach(
          name: 'ParkMobile',
          title: 'ParkMobile',
          domain: 'parkmobile.io',
          breachDate: DateTime(2021, 3, 1),
          pwnCount: 20949025,
          dataClasses: const [
            'Dates of birth', 'Email addresses', 'Names', 'Passwords',
            'Phone numbers', 'Physical addresses'
          ],
          description:
              'In March 2021 the parking payment service ParkMobile suffered a breach exposing 21 million customers.',
        ),
        Breach(
          name: 'Collection1',
          title: 'Collection #1 (combo list)',
          domain: '',
          breachDate: DateTime(2019, 1, 7),
          pwnCount: 772904991,
          dataClasses: const ['Email addresses', 'Passwords'],
          isVerified: false,
          description:
              'A credential-stuffing compilation of 773 million unique email/password pairs aggregated from thousands of earlier breaches.',
        ),
      ];
}
