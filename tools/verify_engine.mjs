#!/usr/bin/env node
/**
 * Footprint Guard — offline engine verification (Node mirror of the Dart
 * security math). Runs WITHOUT Flutter so the formulas, k-Anonymity
 * vectors and platform DB can be proven in any CI/sandbox:
 *   node tools/verify_engine.mjs
 * The Dart unit tests in test/ assert the identical expectations.
 */
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';

let passed = 0, failed = 0;
const ok = (name, cond, extra = '') => {
  if (cond) { passed++; console.log(`  PASS  ${name}`); }
  else { failed++; console.log(`  FAIL  ${name} ${extra}`); }
};
const near = (a, b, eps = 0.01) => Math.abs(a - b) < eps;

// --- 1. k-Anonymity SHA-1 ---------------------------------------------------
console.log('\n[1] k-Anonymity SHA-1');
const sha1 = (s) => createHash('sha1').update(s, 'utf8').digest('hex').toUpperCase();
ok("sha1('password') == public HIBP vector",
  sha1('password') === '5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8');
const split = (s) => { const h = sha1(s); return { prefix: h.slice(0, 5), suffix: h.slice(5) }; };
const sp = split('password');
ok('prefix 5BAA6 / suffix 35 chars', sp.prefix === '5BAA6' && sp.suffix.length === 35);

function parseRange(body, suffix) {
  for (const line of body.split(/\r?\n/)) {
    const i = line.indexOf(':'); if (i <= 0) continue;
    if (line.slice(0, i).trim().toUpperCase() === suffix.toUpperCase()) {
      const n = parseInt(line.slice(i + 1).trim(), 10) || 0;
      return n > 0 ? n : null; // padding entries have count 0
    }
  }
  return null;
}
const cannedRange = [
  '0018A45C4D1DEF81644B54AB7F969B88D65:1',
  '00D4F6E8FA6EECAD2A3AA415EEC418D38EC:2',
  '1E4C9B93F3F0682250B6CF8331B7EE68FD8:9545824',
  '01330C689E5D64F660D6947A93AD634EF8F:0',
].join('\r\n');
ok('range match finds 9,545,824 sightings', parseRange(cannedRange, sp.suffix) === 9545824);
ok('padding (count 0) ignored', parseRange(cannedRange, '01330C689E5D64F660D6947A93AD634EF8F') === null);
ok('absent suffix -> null', parseRange(cannedRange, 'FFFFF') === null);

// --- 2. Input classification (mirrors PrivacyFilterService) -----------------
console.log('\n[2] Input classification');
const emailRe = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/;
const phoneRe = /^\+?[0-9\s\-()]{7,18}$/;
const userRe = /^[A-Za-z0-9._\-]{2,40}$/;
function classify(v) {
  v = v.trim(); if (!v) return 'unknown';
  if (emailRe.test(v)) return 'email';
  const digits = v.replace(/[^0-9]/g, '');
  if (phoneRe.test(v) && digits.length >= 7 && digits.length <= 15 && /^[+0-9]/.test(v)) return 'phone';
  if (userRe.test(v)) return 'username';
  return 'unknown';
}
ok('email classified', classify('user@example.com') === 'email');
ok('Egyptian mobile classified', classify('+20 100 123 4567') === 'phone');
ok('username classified', classify('ahmed.sec_01') === 'username');
ok('garbage -> unknown', classify('bad input with spaces!') === 'unknown');

// --- 3. Threat calculator (mirrors RiskEngine) -------------------------------
console.log('\n[3] Social Engineering Threat Calculator');
const W = { 'Passwords': 18, 'Password hints': 14, 'Security questions and answers': 12,
  'Credit cards': 22, 'Bank account numbers': 22, 'Social security numbers': 25,
  'Passport numbers': 22, 'Government issued IDs': 22, 'Phone numbers': 12,
  'Physical addresses': 14, 'Dates of birth': 10, 'IP addresses': 8,
  'Geographic locations': 6, 'Email addresses': 4, 'Names': 3, 'Usernames': 2,
  'Genders': 1, 'Social media profiles': 3, 'Private messages': 10, 'Photos': 6,
  'Employment': 4, 'Education': 3, 'Financial': 12 };
const recency = (date, now) => {
  const y = (now - date) / (365.25 * 864e5);
  return y <= 1 ? 1 : y <= 3 ? 0.85 : y <= 5 ? 0.7 : y <= 8 ? 0.55 : 0.4;
};
function assess(breaches, platforms, pw, now) {
  let raw = 0;
  for (const b of breaches) {
    const rf = recency(b.date, now) * (b.sensitive ? 1.15 : 1);
    for (const dc of b.dc) raw += (W[dc] ?? 2) * rf;
  }
  const bc = Math.min(raw, 75), pp = Math.min(platforms * 1.5, 25);
  const pwp = pw?.found ? (pw.count > 100000 ? 10 : pw.count > 1000 ? 8 : 6) : 0;
  const score = Math.max(0, Math.min(100, Math.round(bc + pp + pwp)));
  const tier = score <= 20 ? 'safe' : score <= 45 ? 'low' : score <= 70 ? 'moderate' : 'critical';
  return { score, tier, bc, pp, pwp };
}
const NOW = new Date('2025-01-01T00:00:00Z');
ok('recency: 6mo=1.0, 2y=.85, 4y=.70, 7y=.55, 15y=.40',
  recency(new Date('2024-06-01'), NOW) === 1 && recency(new Date('2023-01-01'), NOW) === 0.85 &&
  recency(new Date('2021-01-01'), NOW) === 0.7 && recency(new Date('2018-01-01'), NOW) === 0.55 &&
  recency(new Date('2010-01-01'), NOW) === 0.4);
ok('clean -> 0 safe', assess([], 0, null, NOW).score === 0);
const adobe = assess([{ date: new Date('2024-06-01'), dc: ['Passwords', 'Password hints', 'Email addresses', 'Usernames'] }], 0, null, NOW);
ok('fresh Adobe-style breach = 38 (low)', near(adobe.bc, 38) && adobe.score === 38 && adobe.tier === 'low', JSON.stringify(adobe));
ok('platform penalty 10 -> 15, 40 -> cap 25',
  near(assess([], 10, null, NOW).pp, 15) && assess([], 40, null, NOW).pp === 25);
const worst = assess(
  Array.from({ length: 12 }, () => ({ date: new Date('2024-06-01'), dc: ['Passwords', 'Credit cards', 'Phone numbers'] })),
  30, { found: true, count: 500000 }, NOW);
ok('caps: breach 75 + platforms 25 + password 10 -> 100 critical',
  worst.bc === 75 && worst.pp === 25 && worst.pwp === 10 && worst.score === 100 && worst.tier === 'critical');
ok('sensitive boost x1.15',
  near(assess([{ date: new Date('2024-06-01'), dc: ['Passwords'], sensitive: true }], 0, null, NOW).bc, 20.7));

// Realistic mock scenario proof
const mockScenario = assess([
  { date: new Date('2022-01-01'), dc: ['Email addresses', 'Names', 'Phone numbers', 'Usernames'] },
  { date: new Date('2019-05-24'), dc: ['Email addresses', 'Geographic locations', 'Names', 'Passwords', 'Usernames'] },
  { date: new Date('2013-10-04'), dc: ['Email addresses', 'Password hints', 'Passwords', 'Usernames'] },
], 11, { found: true, count: 9545824 }, new Date());
console.log(`  info  realistic 3-breach/11-platform/pwned-password scenario -> score ${mockScenario.score} (${mockScenario.tier})`);
ok('realistic scenario lands in moderate/critical band', mockScenario.score >= 46);

// --- 4. Platform database -----------------------------------------------------
console.log('\n[4] Platform database');
const db = JSON.parse(readFileSync('data/platforms.json', 'utf8')).platforms;
ok(`>= 50 platforms (actual ${db.length})`, db.length >= 50);
ok('unique names', new Set(db.map(p => p.name)).size === db.length);
ok('all https + {u} template', db.every(p => p.url.startsWith('https://') && p.url.includes('{u}')));
ok('spec-named platforms present (GitHub, Spotify, Steam)',
  ['GitHub', 'Spotify', 'Steam', 'X (Twitter)'].every(n => db.some(p => p.name === n)));
const dartSrc = readFileSync('lib/data/platforms.dart', 'utf8');
ok(`generated Dart contains ${db.length} PlatformDef entries`,
  (dartSrc.match(/PlatformDef\(name:/g) || []).length === db.length);

// --- 5. No-emoji policy scan over Dart + preview sources ----------------------
console.log('\n[5] No-emoji policy');
import('node:fs').then(({ readdirSync, statSync }) => {
  const emojiRe = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]/u;
  const files = [];
  const walk = (d) => { for (const f of readdirSync(d)) { const p = `${d}/${f}`;
    if (statSync(p).isDirectory()) walk(p);
    else if (/\.(dart|html|js|md)$/.test(f) && !p.includes('platforms.js')) files.push(p); } };
  walk('lib'); walk('web_preview');
  const offenders = files.filter(f => emojiRe.test(readFileSync(f, 'utf8')));
  ok(`no emojis in ${files.length} source files`, offenders.length === 0, offenders.join(','));
  console.log(`\n${failed === 0 ? 'ALL CHECKS PASSED' : 'FAILURES PRESENT'} — passed=${passed} failed=${failed}`);
  process.exit(failed ? 1 : 0);
});
