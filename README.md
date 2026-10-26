<div align="center">

<img src="web_preview/icon-192.png" width="96" alt="Footprint Guard radar icon">

# Footprint Guard

### مسح الأثر الرقمي والهندسة الاجتماعية

**OSINT & Digital Footprint Audit for Android** — breach exposure (Have I Been Pwned),
username recon across **60 platforms**, a transparent **Social Engineering Threat Score**,
and a prioritized remediation plan. Privacy-first by design: **k-Anonymity SHA-1 hashing
on-device, zero custom servers, zero storage, zero tracking.**

Amoled Black `#000000` · Liquid Glass · Feather thin-stroke icons · No emojis · Arabic (RTL) + English

</div>

---

## Table of contents

1. [What it does](#what-it-does)
2. [Get the APK](#get-the-apk)
3. [Try the interactive preview](#try-the-interactive-preview)
4. [Privacy & security model](#privacy--security-model)
5. [Threat-score formula](#threat-score-formula)
6. [Architecture](#architecture)
7. [Build from source](#build-from-source)
8. [Mock Audit Mode](#mock-audit-mode)
9. [Reports (PDF / Markdown)](#reports)
10. [Testing & verification](#testing--verification)
11. [Ethics, limitations, known constraints](#ethics-limitations-known-constraints)

---

## What it does

Enter an **email, username or phone number** (the glass search bar detects the type and
morphs its icon), then Footprint Guard runs a five-stage audit with a radar-sweep scanner:

1. **Classify & protect** — input is classified locally; SHA-1 is computed on-device and
   split for k-Anonymity; the identity is only ever displayed redacted (`a•••@e••••.com`).
2. **Breach lookup** — Have I Been Pwned **API v3** breach history (personal API key,
   device → HIBP over TLS, no proxy), plus a keyless **Pwned Passwords** check that is
   pure k-Anonymity (only 5 hash chars leave the phone, `Add-Padding: true`).
3. **Username recon** — WhatsMyName/Holehe-style existence checks against **60 platforms**
   (GitHub, GitLab, Reddit, X, Instagram, TikTok, Telegram, Spotify, Steam, Chess.com,
   Lichess, Dribbble, Medium, Keybase, Bluesky, Duolingo, Snapchat …) with bounded
   concurrency and per-platform reliability ratings.
4. **Threat scoring** — one 0–100 social-engineering exposure score with a graduated
   radar gauge and an exposure-breakdown grid (passwords, phones, IPs, cards, IDs…).
5. **Remediation plan** — prioritized, concrete actions ("Rotate passwords on 3 breached
   sites", "Enable 2FA via Authenticator App", "Remove phone number from public bio"…)
   with effort estimates — then export a professional **PDF or Markdown report**.

## Get the APK

Every push builds a release APK in GitHub Actions
(`.github/workflows/build-apk.yml`, Flutter 3.24.5, JDK 17):

1. Open the repo **Actions** tab → latest *Build Footprint Guard APK (ARM64)* run.
2. Download the **`FootprintGuard-ARM64-APK`** artifact →
   `FootprintGuard-v1.0.0-arm64-v8a.apk`.
3. Install on any ARM64 Android device (Android 7.0+ / API 24+).

The CI artifact is signed with the debug key so it is installable for evaluation.
For store/production signing see [Build from source](#build-from-source).

## Try the interactive preview

`web_preview/` is a pixel-faithful web replica of the app (same glass UI, same engine
math, same mock data). In **LIVE mode its password check calls the real HIBP range API
from your browser** using Web Crypto SHA-1 + k-Anonymity:

```bash
cd web_preview && python3 -m http.server 8080   # then open http://localhost:8080
```

Browser realities are surfaced honestly in the preview: most platform profile pages and
the HIBP v3 API block cross-origin browser reads (CORS), so those checks run natively in
the APK; CORS-open endpoints (e.g. Chess.com / Lichess / Bluesky public APIs) work live
in the browser.

## Privacy & security model

| Property | Implementation |
|---|---|
| Password checks | **k-Anonymity**: SHA-1 computed locally (`PrivacyFilterService`), only the **first 5 hex chars** are sent to `api.pwnedpasswords.com/range/…` with padding; the 35-char suffix is matched **on-device**. The password and its full hash never leave the phone. |
| Email breach lookup | HIBP API v3 inherently requires the account + a personal API key. The request goes **directly from the device to `haveibeenpwned.com` over TLS** with the user's own key (build-time `--dart-define=HIBP_API_KEY=…` or pasted in-app, kept in memory only). There is **no Footprint Guard backend** to proxy, log or store anything. |
| Username recon | Plain HTTPS `GET`s of **public** profile URLs, directly to each platform. |
| Storage | **None.** No databases, no shared-prefs of audit data, no analytics SDKs. State lives in memory and dies with the process. Only user-exported report files are written, on demand. |
| Permissions | `INTERNET` + `ACCESS_NETWORK_STATE` only. `usesCleartextTraffic="false"`. |
| Display | Identities redacted in UI, logs and report headers. |

## Threat-score formula

```
Score = clamp( Σ_breaches Σ_dataclasses (DataTypeWeight × RecencyFactor × SensitivityBoost)   [cap 75]
             + RegisteredPlatformsPenalty = min(25, found × 1.5)
             + PwnedPasswordPenalty       [6 / 8 / 10 by sighting count, cap 10]
             , 0, 100 )

RecencyFactor: ≤1y → 1.00 · ≤3y → 0.85 · ≤5y → 0.70 · ≤8y → 0.55 · older → 0.40
SensitivityBoost: 1.15 for HIBP "sensitive" breaches
Tiers: Safe 0–20 · Low 21–45 · Moderate 46–70 · Critical 71–100
```

Weights (weaponizability for phishing / account takeover): Passwords 18, Credit cards 22,
SSNs/Gov IDs 25, Phone numbers 12, Physical addresses 14, DoB 10, IPs 8, Emails 4, …
(full table in `lib/services/risk_engine.dart`). The formula is unit-tested in Dart and
mirrored in `tools/verify_engine.mjs` (`node tools/verify_engine.mjs` → 22 checks).

## Architecture

```
lib/
├── main.dart                        App bootstrap, Amoled system chrome, RTL/LTR direction
├── app/theme.dart                   FGColors / FGTheme (Amoled + liquid glass tokens, Cairo/Inter)
├── core/privacy_filter_service.dart Classification, SHA-1 k-Anonymity split, redaction
├── data/platforms.dart              GENERATED from data/platforms.json (60 PlatformDefs)
├── models/models.dart               Breach, PlatformHit, RiskAssessment, AuditResult, tiers
├── services/
│   ├── breach_check_service.dart    HIBP API v3 + Pwned Passwords range (k-Anonymity)
│   ├── osint_service.dart           60-platform username recon (concurrency 8, pure evaluate())
│   ├── risk_engine.dart             Social Engineering Threat Calculator
│   ├── remediation_engine.dart      Rule-based prioritized action plan (AR/EN)
│   ├── report_export_service.dart   PDF (printing/pdf) + bilingual Markdown export
│   └── mock_data.dart               Deterministic Mock Audit Mode fixtures
├── state/audit_controller.dart      5-stage audit state machine (ChangeNotifier)
├── l10n/strings.dart                Full Arabic + English string table (no emojis)
└── ui/
    ├── audit_dashboard.dart         AuditDashboard (single-screen experience)
    ├── fg_icons.dart                Feather icon semantic map
    └── widgets/
        ├── glass_card.dart          Liquid Glass surface + ambient glow field
        ├── glass_search_bar.dart    Floating search with type-morphing icon
        ├── risk_gauge_widget.dart   Graduated 270° radar gauge (CustomPainter)
        ├── exposure_grid.dart       Leaked-data-type glass grid
        ├── breach_timeline_card.dart Vertical breach timeline in one glass container
        └── scanner_overlay.dart     Radar-sweep scanner + live terminal log
data/platforms.json                  Single source of truth for the platform DB
tools/gen_platforms.mjs              Regenerates Dart + JS platform DBs from the JSON
tools/verify_engine.mjs              Offline proof of hashing/scoring/classification (Node)
tools/gen_icons.py                   Launcher icon generation (radar mark, stdlib PNG)
test/                                Dart unit tests (privacy, risk, range-parse, OSINT eval, DB)
web_preview/                         Interactive web replica (real browser k-Anonymity call)
Android/                             Flutter 3.24 Android project, arm64-v8a, minSdk 24
.github/workflows/build-apk.yml      CI: verify → pub get → analyze → test → release APK
```

The platform database is **generated**: edit `data/platforms.json`, run
`node tools/gen_platforms.mjs`, and both `lib/data/platforms.dart` and
`web_preview/platforms.js` are rewritten (60 platforms, validated ≥ 50).

## Build from source

Requirements: Flutter **3.24.5** (stable), JDK 17, Android SDK.

```bash
flutter pub get

# The exact product build — standalone ARM64 release APK:
flutter build apk --release --target-platform android-arm64
# -> build/app/outputs/flutter-apk/app-release.apk  (arm64-v8a only, also pinned via abiFilters)

# Optionally bake in your personal HIBP key (never commit it):
flutter build apk --release --target-platform android-arm64 \
  --dart-define=HIBP_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Emulator run (Mock Audit Mode is ON by default — no key needed):
flutter run

# Tests
flutter test
node tools/verify_engine.mjs
```

**Production signing:** create `Android/key.properties` (git-ignored) —

```properties
storePassword=…
keyPassword=…
keyAlias=…
storeFile=/absolute/path/upload-keystore.jks
```

`Android/app/build.gradle` picks it up automatically; without it, release builds fall
back to the debug key (fine for CI/evaluation, **not** for Play Store).

**Getting a HIBP key:** https://haveibeenpwned.com/API/Key (needed only for live email
breach lookup; password k-Anonymity + username recon are keyless).

## Mock Audit Mode

**ON by default** (toggle in Audit Settings). It deterministically simulates breaches,
platform hits and password results from the entered identity (same input → same audit),
using public metadata of well-known historical breaches as realistic fixtures. Every
mock surface is badged **SIMULATED / محاكاة**, including exported reports — the app never
claims the identity was really in those breaches. This makes the scanner animation,
timeline, gauge, remediation and exports fully testable in an emulator with no API keys
and no network.

## Reports

- **PDF** — minimalist, high-contrast, printer-friendly A4 document (cover score header,
  exposure table, timeline, accounts, remediation), shared via the system share sheet or
  sent to Print. Labels are English because the standard PDF fonts (Helvetica) cannot
  shape Arabic script — stated in-app.
- **Markdown** — fully bilingual (Arabic/English), saved to app documents or copied to
  the clipboard. Identical structure to the PDF.

## Testing & verification

```bash
flutter test                    # Dart: SHA-1 HIBP vector, range parsing (+padding),
                                # score formula/caps/tiers/recency, classification,
                                # redaction, OSINT evaluate(), platform DB integrity
node tools/verify_engine.mjs    # Same expectations proven offline in Node (22 checks),
                                # + automated no-emoji scan of all sources
```

CI runs both, plus `flutter analyze`, before compiling the APK.

## Ethics, limitations, known constraints

- **Authorized use only.** Footprint Guard is a *defensive* self-audit tool. Checking
  usernames/emails you do not own may violate platform terms and local law — audit your
  own footprint or others' only with consent.
- **Usernames are not identities.** A "found" hit means the handle exists, not that it
  belongs to the same person. Reliability ratings are shown per platform; JS-heavy or
  bot-walled sites (X, Instagram, TikTok…) are rated `low` and can false-negative.
- **Phone inputs** cannot be breach-checked via HIBP (no phone corpus) and do not run
  username recon; they receive phone-specific scoring/remediation (plus simulation in
  Mock Mode).
- **Rate limits:** HIBP v3 is rate-limited per key (HTTP 429 surfaced in-app); platform
  sweeps use gentle concurrency (8) and 7s timeouts.
- Scores are **risk indicators**, not verdicts — always read the remediation plan.
- PDF export is Latin-script (see above); use Markdown for the full Arabic report.

---

<div align="center">

Footprint Guard v1.0.0 · Flutter 3.24 · Android ARM64 · Sources: Have I Been Pwned ·
public platform profile pages · Feather Icons · Cairo/Inter

</div>
