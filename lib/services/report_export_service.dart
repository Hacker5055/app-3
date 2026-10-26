import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';

/// ReportExportService — official exposure-report generation.
///
///  * Markdown: fully bilingual (Arabic / English), copyable & saveable.
///  * PDF: minimalist, high-contrast, printer-friendly document
///    (white background, near-black text). PDF labels are rendered in
///    English because the bundled standard PDF fonts (Helvetica) cannot
///    shape Arabic script; the Markdown export carries the full Arabic
///    report. This is stated openly in-app and in the README.
class ReportExportService {
  const ReportExportService();

  String _tierLabel(ThreatTier t, bool ar) {
    switch (t) {
      case ThreatTier.safe:
        return ar ? 'آمن (0-20)' : 'Safe (0-20)';
      case ThreatTier.low:
        return ar ? 'منخفض (21-45)' : 'Low (21-45)';
      case ThreatTier.moderate:
        return ar ? 'متوسط (46-70)' : 'Moderate (46-70)';
      case ThreatTier.critical:
        return ar ? 'حرج (71-100)' : 'Critical (71-100)';
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------- Markdown
  String buildMarkdown(AuditResult r, {required bool arabic}) {
    final ar = arabic;
    final b = StringBuffer();
    b.writeln(ar
        ? '# تقرير تدقيق الأثر الرقمي — Footprint Guard'
        : '# Digital Footprint Audit Report — Footprint Guard');
    b.writeln();
    if (r.mockMode) {
      b.writeln(ar
          ? '> تنبيه: تم إنشاء هذا التقرير في وضع التدقيق التجريبي (بيانات محاكاة).'
          : '> Notice: generated in Mock Audit Mode (simulated data).');
      b.writeln();
    }
    b.writeln('| ${ar ? 'البند' : 'Field'} | ${ar ? 'القيمة' : 'Value'} |');
    b.writeln('|---|---|');
    b.writeln('| ${ar ? 'الهوية المدروسة (مموّهة)' : 'Audited identity (redacted)'} | `${r.redactedInput}` |');
    b.writeln('| ${ar ? 'نوع الإدخال' : 'Input type'} | ${r.inputKind.name} |');
    b.writeln('| ${ar ? 'تاريخ التقرير' : 'Generated'} | ${_fmtDate(r.generatedAt)} |');
    b.writeln('| ${ar ? 'درجة خطر التعرض' : 'Exposure Risk Score'} | **${r.risk.score}/100 — ${_tierLabel(r.risk.tier, ar)}** |');
    b.writeln('| ${ar ? 'مكوّن التسريبات' : 'Breach component'} | ${r.risk.breachComponent.toStringAsFixed(1)}/75 |');
    b.writeln('| ${ar ? 'عقوبة المنصات المسجلة' : 'Registered-platforms penalty'} | ${r.risk.platformPenalty.toStringAsFixed(1)}/25 |');
    b.writeln('| ${ar ? 'عقوبة كلمة المرور المُسربة' : 'Pwned-password penalty'} | ${r.risk.passwordPenalty.toStringAsFixed(1)}/10 |');
    b.writeln();
    b.writeln(ar
        ? '## المعادلة: الدرجة = Σ(وزن نوع البيانات × عامل الحداثة) + عقوبة المنصات المسجلة + عقوبة كلمة المرور المُسربة — بحد أقصى 100.'
        : '## Formula: Score = sum(DataTypeWeight x RecencyFactor) + RegisteredPlatformsPenalty + PwnedPasswordPenalty, capped at 100.');
    b.writeln();

    b.writeln(ar ? '## تفصيل البيانات المُعرّضة' : '## Exposure Breakdown');
    b.writeln();
    b.writeln('| ${ar ? 'نوع البيانات' : 'Data type'} | ${ar ? 'عدد التسريبات' : 'Breaches'} | ${ar ? 'المساهمة المرجحة' : 'Weighted contribution'} |');
    b.writeln('|---|---:|---:|');
    for (final e in r.risk.exposureBreakdown) {
      b.writeln('| ${e.dataClass} | ${e.breachCount} | ${e.weightedScore.toStringAsFixed(1)} |');
    }
    b.writeln();

    b.writeln(ar ? '## الخط الزمني للتسريبات (${r.breaches.length})' : '## Breach Timeline (${r.breaches.length})');
    b.writeln();
    if (r.breachLookupSkippedNoKey) {
      b.writeln(ar
          ? 'تم تخطي فحص التسريبات: يلزم إدخال مفتاح HIBP API شخصي لتفعيل فحص البريد.'
          : 'Breach lookup skipped: a personal HIBP API key is required for email breach checks.');
      b.writeln();
    }
    for (final breach in r.breaches) {
      b.writeln('### ${breach.title} — ${_fmtDate(breach.breachDate)}');
      b.writeln('- ${ar ? 'النطاق' : 'Domain'}: ${breach.domain.isEmpty ? '—' : breach.domain}');
      b.writeln('- ${ar ? 'الحسابات المتأثرة' : 'Accounts affected'}: ${breach.pwnCount}');
      b.writeln('- ${ar ? 'البيانات المُسربة' : 'Data exposed'}: ${breach.dataClasses.join(', ')}');
      b.writeln('- ${ar ? 'موثّق' : 'Verified'}: ${breach.isVerified}${breach.isSensitive ? ' · ${ar ? 'حساس' : 'Sensitive'}' : ''}');
      if (breach.description.isNotEmpty) {
        final clean = breach.description.replaceAll(RegExp(r'<[^>]*>'), '');
        b.writeln('- $clean');
      }
      b.writeln();
    }

    final found = r.foundPlatforms;
    b.writeln(ar
        ? '## الحسابات العامة المكتشفة (${found.length} من ${r.platformsChecked} منصة تم فحصها)'
        : '## Discovered Public Accounts (${found.length} of ${r.platformsChecked} platforms checked)');
    b.writeln();
    b.writeln(ar
        ? '> ملاحظة منهجية: أسماء المستخدمين ليست هويات فريدة؛ كل نتيجة مؤشر يستلزم التحقق اليدوي.'
        : '> Methodology note: usernames are not unique identities; each hit is an indicator requiring manual verification.');
    b.writeln();
    for (final h in found) {
      b.writeln('- **${h.platform.name}** (${h.platform.category}, ${ar ? 'موثوقية' : 'reliability'}: ${h.platform.reliability.name}) — ${h.url}');
    }
    b.writeln();

    if (r.passwordResult != null) {
      final p = r.passwordResult!;
      b.writeln(ar ? '## فحص كلمة المرور (k-Anonymity)' : '## Password Check (k-Anonymity)');
      b.writeln();
      b.writeln(ar
          ? 'تم إرسال بادئة SHA-1 ذات 5 أحرف فقط (${p.sha1Prefix})؛ كلمة المرور نفسها لم تغادر الجهاز أبدًا.'
          : 'Only the 5-character SHA-1 prefix (${p.sha1Prefix}) was transmitted; the password itself never left the device.');
      b.writeln(p.found
          ? (ar
              ? '**النتيجة: مُخترقة — ظهرت ${p.count} مرة في تسريبات معروفة.**'
              : '**Result: PWNED — seen ${p.count} times in known breaches.**')
          : (ar
              ? 'النتيجة: لم تظهر في قواعد التسريبات المعروفة.'
              : 'Result: not found in known breach corpora.'));
      b.writeln();
    }

    b.writeln(ar ? '## خطة المعالجة' : '## Remediation Plan');
    b.writeln();
    var i = 1;
    for (final s in r.remediation) {
      b.writeln('${i++}. **[${s.priority.name.toUpperCase()}] ${s.titleFor(ar)}** (~${s.effortMinutes} ${ar ? 'دقيقة' : 'min'})');
      b.writeln('   ${s.bodyFor(ar)}');
    }
    b.writeln();
    b.writeln('---');
    b.writeln(ar
        ? 'وُلّد محليًا بالكامل بواسطة Footprint Guard. لا خوادم وسيطة، لا تخزين، لا تتبّع.'
        : 'Generated entirely on-device by Footprint Guard. No intermediary servers, no storage, no tracking.');
    return b.toString();
  }

  Future<File> saveMarkdown(AuditResult r, {required bool arabic}) async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = _fmtDate(r.generatedAt);
    final file = File('${dir.path}/footprint-guard-report-$ts.md');
    await file.writeAsString(buildMarkdown(r, arabic: arabic));
    return file;
  }

  // --------------------------------------------------------------------- PDF
  Future<Uint8List> buildPdf(AuditResult r) async {
    final doc = pw.Document(
      title: 'Footprint Guard — Exposure Report',
      author: 'Footprint Guard',
      subject: 'Digital Footprint Audit',
    );
    final ink = PdfColor.fromHex('111318');
    final grey = PdfColor.fromHex('5A6068');
    final accent = r.risk.tier == ThreatTier.critical
        ? PdfColor.fromHex('D92D20')
        : r.risk.tier == ThreatTier.moderate
            ? PdfColor.fromHex('B54708')
            : PdfColor.fromHex('027A48');

    pw.Widget heading(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: ink)),
        );
    pw.Widget kv(String k, String v) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(children: [
            pw.SizedBox(
                width: 170,
                child: pw.Text(k,
                    style: pw.TextStyle(fontSize: 9.5, color: grey))),
            pw.Expanded(
                child: pw.Text(v,
                    style: pw.TextStyle(fontSize: 9.5, color: ink))),
          ]),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 48, 42, 48),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Footprint Guard · Page ${ctx.pageNumber}/${ctx.pagesCount} · Generated on-device',
            style: pw.TextStyle(fontSize: 8, color: grey),
          ),
        ),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: ink, width: 1.4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FOOTPRINT GUARD',
                          style: pw.TextStyle(
                              fontSize: 17,
                              fontWeight: pw.FontWeight.bold,
                              color: ink,
                              letterSpacing: 1.2)),
                      pw.Text('Digital Footprint & Social Engineering Exposure Report',
                          style: pw.TextStyle(fontSize: 9.5, color: grey)),
                    ]),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('${r.risk.score}/100',
                          style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: accent)),
                      pw.Text(_tierLabel(r.risk.tier, false).toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: accent)),
                    ]),
              ],
            ),
          ),
          if (r.mockMode)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                  'NOTICE: This report was generated in Mock Audit Mode with simulated data.',
                  style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromHex('B54708'),
                      fontWeight: pw.FontWeight.bold)),
            ),
          heading('Audit Summary'),
          kv('Audited identity (redacted)', r.redactedInput),
          kv('Input type', r.inputKind.name),
          kv('Generated', _fmtDate(r.generatedAt)),
          kv('Breach component', '${r.risk.breachComponent.toStringAsFixed(1)} / 75'),
          kv('Registered-platforms penalty',
              '${r.risk.platformPenalty.toStringAsFixed(1)} / 25'),
          kv('Pwned-password penalty',
              '${r.risk.passwordPenalty.toStringAsFixed(1)} / 10'),
          kv('Formula',
              'Score = sum(DataTypeWeight x RecencyFactor) + Platforms + Password (max 100)'),
          heading('Exposure Breakdown'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('D9DDE3'), width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1.4),
            },
            children: [
              pw.TableRow(
                decoration:
                    pw.BoxDecoration(color: PdfColor.fromHex('F2F4F7')),
                children: [
                  for (final h in ['Data type', 'Breaches', 'Weighted'])
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(h,
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: ink))),
                ],
              ),
              for (final e in r.risk.exposureBreakdown)
                pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(e.dataClass,
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: e.exposed
                                  ? PdfColor.fromHex('D92D20')
                                  : grey,
                              fontWeight: e.exposed
                                  ? pw.FontWeight.bold
                                  : pw.FontWeight.normal))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${e.breachCount}',
                          style: pw.TextStyle(fontSize: 9, color: ink))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(e.weightedScore.toStringAsFixed(1),
                          style: pw.TextStyle(fontSize: 9, color: ink))),
                ]),
            ],
          ),
          heading('Breach Timeline (${r.breaches.length})'),
          if (r.breachLookupSkippedNoKey)
            pw.Text(
                'Breach lookup skipped: a personal HIBP API key is required for email breach checks.',
                style: pw.TextStyle(fontSize: 9.5, color: grey)),
          for (final breach in r.breaches)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.only(left: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                    left: pw.BorderSide(
                        color: breach.isSensitive
                            ? PdfColor.fromHex('D92D20')
                            : PdfColor.fromHex('98A2B3'),
                        width: 2)),
              ),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(breach.title,
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: ink)),
                          pw.Text(_fmtDate(breach.breachDate),
                              style: pw.TextStyle(fontSize: 9, color: grey)),
                        ]),
                    pw.Text(
                        '${breach.domain.isEmpty ? '—' : breach.domain} · ${breach.pwnCount} accounts · ${breach.isVerified ? 'verified' : 'unverified'}${breach.isSensitive ? ' · SENSITIVE' : ''}',
                        style: pw.TextStyle(fontSize: 8.5, color: grey)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Text('Exposed: ${breach.dataClasses.join(', ')}',
                          style: pw.TextStyle(fontSize: 9, color: ink)),
                    ),
                  ]),
            ),
          heading(
              'Discovered Public Accounts (${r.foundPlatforms.length} of ${r.platformsChecked} checked)'),
          pw.Text(
              'Usernames are not unique identities; each hit is an indicator requiring manual verification.',
              style: pw.TextStyle(
                  fontSize: 8.5, color: grey, fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 6),
          for (final h in r.foundPlatforms)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(children: [
                pw.SizedBox(
                    width: 130,
                    child: pw.Text(h.platform.name,
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: ink))),
                pw.SizedBox(
                    width: 110,
                    child: pw.Text(
                        '${h.platform.category} · ${h.platform.reliability.name}',
                        style: pw.TextStyle(fontSize: 8.5, color: grey))),
                pw.Expanded(
                    child: pw.Text(h.url,
                        style: pw.TextStyle(fontSize: 8.5, color: ink))),
              ]),
            ),
          if (r.passwordResult != null) heading('Password Check (k-Anonymity)'),
          if (r.passwordResult != null)
            pw.Text(
              'Only the 5-character SHA-1 prefix (${r.passwordResult!.sha1Prefix}) was transmitted; the password never left the device. Result: ${r.passwordResult!.found ? 'PWNED — seen ${r.passwordResult!.count} times' : 'not found in known corpora'}.',
              style: pw.TextStyle(fontSize: 9.5, color: ink),
            ),
          heading('Remediation Plan'),
          for (var i = 0; i < r.remediation.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 9),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                        '${i + 1}. [${r.remediation[i].priority.name.toUpperCase()}] ${r.remediation[i].titleEn} (~${r.remediation[i].effortMinutes} min)',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: ink)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 14, top: 2),
                      child: pw.Text(r.remediation[i].bodyEn,
                          style: pw.TextStyle(fontSize: 9, color: grey)),
                    ),
                  ]),
            ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 14),
            child: pw.Text(
                'Generated entirely on-device by Footprint Guard. No intermediary servers, no storage, no tracking. Sources: Have I Been Pwned (haveibeenpwned.com), public profile pages of the listed platforms.',
                style: pw.TextStyle(fontSize: 8, color: grey)),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> sharePdf(AuditResult r) async {
    final bytes = await buildPdf(r);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'footprint-guard-report-${_fmtDate(r.generatedAt)}.pdf',
    );
  }

  Future<void> printPdf(AuditResult r) async {
    final bytes = await buildPdf(r);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
