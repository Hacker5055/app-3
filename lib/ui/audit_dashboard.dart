import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../state/audit_controller.dart';
import 'fg_icons.dart';
import 'widgets/breach_timeline_card.dart';
import 'widgets/exposure_grid.dart';
import 'widgets/glass_card.dart';
import 'widgets/glass_search_bar.dart';
import 'widgets/risk_gauge_widget.dart';
import 'widgets/scanner_overlay.dart';

/// AuditDashboard — the single-screen premium audit experience.
/// Amoled black + liquid glass, Feather thin-stroke icons, no emojis.
class AuditDashboard extends StatefulWidget {
  final AuditController controller;
  const AuditDashboard({super.key, required this.controller});

  @override
  State<AuditDashboard> createState() => _AuditDashboardState();
}

class _AuditDashboardState extends State<AuditDashboard> {
  final TextEditingController _inputCtrl = TextEditingController();
  final TextEditingController _pwCtrl = TextEditingController();
  final TextEditingController _keyCtrl = TextEditingController();
  InputKind _kind = InputKind.unknown;

  AuditController get c => widget.controller;
  S get s => c.s;

  @override
  void initState() {
    super.initState();
    _keyCtrl.text = c.hibpApiKey;
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _pwCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _submit() {
    final v = _inputCtrl.text.trim();
    if (v.isEmpty) {
      _snack(s.enterSomething);
      return;
    }
    FocusScope.of(context).unfocus();
    c.runAudit(v, passwordToCheck: _pwCtrl.text);
  }

  String _tierLabel(ThreatTier t) {
    switch (t) {
      case ThreatTier.safe:
        return s.tierSafe;
      case ThreatTier.low:
        return s.tierLow;
      case ThreatTier.moderate:
        return s.tierModerate;
      case ThreatTier.critical:
        return s.tierCritical;
    }
  }

  Color _priorityColor(RemediationPriority p) {
    switch (p) {
      case RemediationPriority.critical:
        return FGColors.crimson;
      case RemediationPriority.high:
        return FGColors.orangeDeep;
      case RemediationPriority.medium:
        return FGColors.amber;
      case RemediationPriority.low:
        return FGColors.emeraldDim;
    }
  }

  String _priorityLabel(RemediationPriority p) {
    switch (p) {
      case RemediationPriority.critical:
        return s.priorityCritical;
      case RemediationPriority.high:
        return s.priorityHigh;
      case RemediationPriority.medium:
        return s.priorityMedium;
      case RemediationPriority.low:
        return s.priorityLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final result = c.result;
        final glow = result != null
            ? FGColors.tierColorName(result.risk.tier.name)
            : FGColors.emerald;
        return Scaffold(
          body: Stack(
            children: [
              AmbientGlow(glowColor: glow),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(),
                      const SizedBox(height: 22),
                      if (result == null) _hero(),
                      if (result == null) const SizedBox(height: 20),
                      GlassSearchBar(
                        controller: _inputCtrl,
                        kind: _kind,
                        s: s,
                        busy: c.isScanning,
                        onChanged: (v) =>
                            setState(() => _kind = c.privacy.classify(v)),
                        onSubmit: _submit,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(FGI.lock, size: 12, color: FGColors.textLow),
                          const SizedBox(width: 6),
                          Expanded(child: Text(s.kAnonNote, style: FGTxt.small)),
                        ],
                      ),
                      if (c.error != null) ...[
                        const SizedBox(height: 14),
                        GlassCard(
                          borderColor: FGColors.crimson.withOpacity(0.5),
                          child: Row(
                            children: [
                              const Icon(FGI.alertTriangle,
                                  size: 17, color: FGColors.crimson),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(c.error!, style: FGTxt.body)),
                            ],
                          ),
                        ),
                      ],
                      if (result != null) ...[
                        const SizedBox(height: 22),
                        _gaugeSection(result),
                        const SizedBox(height: 26),
                        SectionHeader(
                          icon: FGI.grid,
                          title: s.exposureBreakdown,
                        ),
                        ExposureGrid(
                            items: result.risk.exposureBreakdown, s: s),
                        const SizedBox(height: 26),
                        SectionHeader(
                          icon: FGI.clock,
                          title: s.breachTimeline,
                          trailing: '${result.breaches.length}',
                        ),
                        if (result.breachLookupSkippedNoKey) ...[
                          GlassCard(
                            borderColor: FGColors.amber.withOpacity(0.45),
                            child: Row(
                              children: [
                                const Icon(FGI.key,
                                    size: 16, color: FGColors.amber),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(s.noKeyNotice, style: FGTxt.small)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        BreachTimeline(breaches: result.breaches, s: s),
                        if (result.platformHits.isNotEmpty) ...[
                          const SizedBox(height: 26),
                          _platformsSection(result),
                        ],
                        const SizedBox(height: 26),
                        SectionHeader(
                          icon: FGI.shield,
                          title: s.remediation,
                          trailing: '${result.remediation.length}',
                        ),
                        _remediationList(result),
                        const SizedBox(height: 26),
                        SectionHeader(icon: FGI.fileText, title: s.exportTitle),
                        _exportSection(result),
                      ],
                      const SizedBox(height: 26),
                      SectionHeader(icon: FGI.key, title: s.passwordCheck),
                      _passwordCard(),
                      const SizedBox(height: 26),
                      SectionHeader(icon: FGI.sliders, title: s.settings),
                      _settingsCard(),
                      const SizedBox(height: 22),
                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(FGI.lock,
                                    size: 12, color: FGColors.textLow),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    s.privacyNote,
                                    textAlign: TextAlign.center,
                                    style: FGTxt.small,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Footprint Guard v1.0.0 · ARM64 · HIBP · 60-platform OSINT',
                              style: TextStyle(
                                  fontSize: 10, color: FGColors.textLow),
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (c.isScanning)
                ScannerOverlay(
                  stage: c.stageLabel,
                  progress: c.progress,
                  logLines: c.logLines,
                  scanningLabel: s.scanning,
                ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ Header
  Widget _header() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: FGColors.glassFill,
            border: Border.all(color: FGColors.glassBorder, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: FGColors.emerald.withOpacity(0.14),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Icon(FGI.shield, size: 20, color: FGColors.emerald),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.appName,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: FGColors.textHi)),
              Text(s.appTagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10.5, color: FGColors.textLow)),
            ],
          ),
        ),
        GlassChip(
          label: c.mockMode ? s.simulatedBadge : s.liveBadge,
          icon: c.mockMode ? FGI.layers : FGI.activity,
          color: c.mockMode ? FGColors.amber : FGColors.emerald,
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: c.toggleLanguage,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: FGColors.glassFill,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: FGColors.glassBorder, width: 0.8),
            ),
            child: Text(
              c.arabic ? 'EN' : 'عربي',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FGColors.textHi),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.radarIdle, style: FGTxt.h1),
        const SizedBox(height: 8),
        Text(s.radarIdleSub, style: FGTxt.body),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            GlassChip(
                icon: FGI.database,
                label: s.t('Breach corpora (HIBP)', 'قواعد التسريبات (HIBP)')),
            GlassChip(
                icon: FGI.globe, label: s.t('60 platforms', '60 منصة')),
            GlassChip(
                icon: FGI.key, label: s.t('k-Anonymity SHA-1', 'k-Anonymity SHA-1')),
            GlassChip(
                icon: FGI.trendingUp,
                label: s.t('Threat scoring', 'درجة التهديد')),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------------- Gauge
  Widget _gaugeSection(AuditResult result) {
    final risk = result.risk;
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(FGI.user, size: 14, color: FGColors.textMid),
              const SizedBox(width: 7),
              Text(s.identity, style: FGTxt.eyebrow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.redactedInput,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontFamily: 'monospace',
                      color: FGColors.textHi),
                ),
              ),
              if (result.mockMode)
                GlassChip(label: s.simulatedBadge, color: FGColors.amber),
            ],
          ),
          const SizedBox(height: 6),
          RiskGaugeWidget(
            score: risk.score,
            tier: risk.tier,
            tierLabel: _tierLabel(risk.tier),
            caption: s.riskScore,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _stat('${result.breaches.length}', s.breaches, FGI.database),
              _statDivider(),
              _stat(
                '${result.foundPlatforms.length}/${result.platformsChecked}',
                s.platforms,
                FGI.globe,
              ),
              _statDivider(),
              _stat(
                '${result.remediation.length}',
                s.t('actions', 'إجراء وقائي'),
                FGI.shield,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _componentBar(
              s.breachComponent, risk.breachComponent, 75, FGColors.crimson),
          const SizedBox(height: 10),
          _componentBar(
              s.platformPenalty, risk.platformPenalty, 25, FGColors.amber),
          const SizedBox(height: 10),
          _componentBar(
              s.passwordPenalty, risk.passwordPenalty, 10, FGColors.orangeDeep),
          const SizedBox(height: 18),
          _GlassButton(
            icon: FGI.refresh,
            label: s.newAudit,
            onTap: () {
              c.reset();
              setState(() => _kind = InputKind.unknown);
            },
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 15, color: FGColors.textMid),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: FGColors.textHi)),
          Text(label, style: FGTxt.small),
        ],
      ),
    );
  }

  Widget _statDivider() =>
      Container(width: 0.7, height: 38, color: FGColors.glassBorderSoft);

  Widget _componentBar(String label, double value, double max, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: FGTxt.small),
            Text('${value.toStringAsFixed(1)} / ${max.round()}',
                style: FGTxt.mono),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
                begin: 0, end: (value / max).clamp(0.0, 1.0).toDouble()),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 4,
              backgroundColor: const Color(0x14FFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- Platforms
  Widget _platformsSection(AuditResult result) {
    final found = result.foundPlatforms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          icon: FGI.globe,
          title: s.accountsFound,
          trailing: '${found.length}/${result.platformsChecked} ${s.checked}',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(s.usernameMethodNote, style: FGTxt.small),
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < found.length; i++) ...[
                _platformRow(found[i]),
                if (i != found.length - 1)
                  const Divider(height: 1, color: FGColors.glassBorderSoft),
              ],
              if (found.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      const Icon(FGI.checkCircle,
                          size: 16, color: FGColors.emerald),
                      const SizedBox(width: 9),
                      Expanded(
                          child: Text(
                              s.t('No public accounts confirmed for this username.',
                                  'لم يتم تأكيد أي حسابات عامة لاسم المستخدم هذا.'),
                              style: FGTxt.body)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _platformRow(PlatformHit hit) {
    final relColor = hit.platform.reliability.name == 'high'
        ? FGColors.emeraldDim
        : hit.platform.reliability.name == 'medium'
            ? FGColors.amber
            : FGColors.orangeDeep;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FGColors.glassFill,
              borderRadius: BorderRadius.circular(11),
              border:
                  Border.all(color: FGColors.glassBorderSoft, width: 0.7),
            ),
            child: Icon(FGI.forCategory(hit.platform.category),
                size: 16, color: FGColors.textHi),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hit.platform.name,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: FGColors.textHi)),
                Text(
                  hit.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: FGColors.textLow),
                ),
              ],
            ),
          ),
          GlassChip(
            label:
                '${s.categoryLabel(hit.platform.category)} · ${hit.platform.reliability.name}',
            color: relColor,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- Remediation
  Widget _remediationList(AuditResult result) {
    return Column(
      children: [
        for (var i = 0; i < result.remediation.length; i++) ...[
          _remediationCard(result.remediation[i], i + 1),
          if (i != result.remediation.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _remediationCard(RemediationStep step, int number) {
    final color = _priorityColor(step.priority);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.10),
              border: Border.all(color: color.withOpacity(0.4), width: 0.8),
            ),
            child: Icon(FGI.forKey(step.iconKey), size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _priorityLabel(step.priority),
                      style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    GlassChip(
                      label: '~${step.effortMinutes} ${s.minutes}',
                      icon: FGI.clock,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.titleFor(c.arabic),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: FGColors.textHi,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 5),
                Text(step.bodyFor(c.arabic), style: FGTxt.small.copyWith(
                    color: FGColors.textMid, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ Export
  Widget _exportSection(AuditResult result) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _GlassButton(
                  icon: FGI.share,
                  label: s.exportPdf,
                  primary: true,
                  onTap: () async {
                    try {
                      await c.reports.sharePdf(result);
                    } catch (e) {
                      _snack('$e');
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GlassButton(
                  icon: FGI.printer,
                  label: s.t('Print', 'طباعة'),
                  onTap: () async {
                    try {
                      await c.reports.printPdf(result);
                    } catch (e) {
                      _snack('$e');
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _GlassButton(
                  icon: FGI.download,
                  label: s.exportMd,
                  onTap: () async {
                    try {
                      final f =
                          await c.reports.saveMarkdown(result, arabic: c.arabic);
                      _snack('${s.savedTo} ${f.path}');
                    } catch (e) {
                      _snack('$e');
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GlassButton(
                  icon: FGI.copy,
                  label: s.copyMd,
                  onTap: () async {
                    final md = c.reports.buildMarkdown(result, arabic: c.arabic);
                    await Clipboard.setData(ClipboardData(text: md));
                    _snack(s.copied);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(s.pdfLangNote, style: FGTxt.small),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Password
  Widget _passwordCard() {
    final pw = c.result?.passwordResult ?? c.standalonePasswordResult;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.passwordHint, style: FGTxt.body),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pwCtrl,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(
                      fontSize: 14, color: FGColors.textHi),
                  decoration: _inputDeco('••••••••••', FGI.key),
                ),
              ),
              const SizedBox(width: 10),
              _GlassButton(
                icon: FGI.search,
                label: s.check,
                primary: true,
                busy: c.passwordBusy,
                onTap: () => c.checkPassword(_pwCtrl.text),
              ),
            ],
          ),
          if (pw != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: (pw.found ? FGColors.crimson : FGColors.emerald)
                    .withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (pw.found ? FGColors.crimson : FGColors.emerald)
                      .withOpacity(0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    pw.found ? FGI.alertTriangle : FGI.checkCircle,
                    size: 18,
                    color: pw.found ? FGColors.crimson : FGColors.emerald,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pw.found
                              ? '${s.pwned} — ${s.seenTimes} ${pw.count} ${s.timesSuffix}'
                              : s.notPwned,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: pw.found
                                ? FGColors.crimson
                                : FGColors.emerald,
                          ),
                        ),
                        Text(
                          'SHA-1 prefix: ${pw.sha1Prefix} · suffix matched locally',
                          textDirection: TextDirection.ltr,
                          style: FGTxt.mono,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Settings
  Widget _settingsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FGColors.glassFill,
                  border:
                      Border.all(color: FGColors.glassBorderSoft, width: 0.7),
                ),
                child: const Icon(FGI.layers, size: 17, color: FGColors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.mockMode,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: FGColors.textHi)),
                    Text(s.mockModeDesc, style: FGTxt.small),
                  ],
                ),
              ),
              Switch(value: c.mockMode, onChanged: c.setMockMode),
            ],
          ),
          const SizedBox(height: 16),
          Text(s.hibpKey, style: FGTxt.eyebrow),
          const SizedBox(height: 8),
          TextField(
            controller: _keyCtrl,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (v) => c.hibpApiKey = v.trim(),
            style: const TextStyle(fontSize: 13, color: FGColors.textHi),
            decoration: _inputDeco('hibp-api-key', FGI.key),
          ),
          const SizedBox(height: 6),
          Text(s.hibpKeyHint, style: FGTxt.small),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(FGI.globe, size: 15, color: FGColors.textMid),
              const SizedBox(width: 8),
              Text(s.language, style: FGTxt.body),
              const Spacer(),
              _langChip('العربية', c.arabic, () {
                if (!c.arabic) c.toggleLanguage();
              }),
              const SizedBox(width: 8),
              _langChip('English', !c.arabic, () {
                if (c.arabic) c.toggleLanguage();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? FGColors.emerald.withOpacity(0.12)
              : FGColors.glassFill,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? FGColors.emerald : FGColors.glassBorderSoft,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? FGColors.emerald : FGColors.textMid,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: FGColors.textLow),
      prefixIcon: Icon(icon, size: 16, color: FGColors.textMid),
      filled: true,
      fillColor: const Color(0x0DFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide:
            const BorderSide(color: FGColors.glassBorderSoft, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: FGColors.emeraldDim, width: 0.9),
      ),
    );
  }
}

/// Glass action button (primary = emerald gradient orb style).
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool busy;
  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: busy ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: primary
                ? const LinearGradient(
                    colors: [FGColors.emerald, FGColors.emeraldDim])
                : null,
            color: primary ? null : FGColors.glassFill,
            border: primary
                ? null
                : Border.all(color: FGColors.glassBorder, width: 0.8),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: FGColors.emerald.withOpacity(0.28),
                      blurRadius: 16,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              else
                Icon(icon,
                    size: 16,
                    color: primary ? Colors.black : FGColors.textHi),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primary ? Colors.black : FGColors.textHi,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
