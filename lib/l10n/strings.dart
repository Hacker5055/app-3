/// Footprint Guard — bilingual string table (Arabic primary, English).
/// No emojis are used anywhere in the UI or in these strings.
class S {
  final bool ar;
  const S(this.ar);
  String t(String en, String arText) => ar ? arText : en;

  String get appName => t('Footprint Guard', 'حارس الأثر الرقمي');
  String get appTagline => t(
      'Digital Footprint & Social Engineering Audit',
      'مسح الأثر الرقمي والهندسة الاجتماعية');
  String get searchHint =>
      t('Email, username, or phone number', 'بريد إلكتروني أو اسم مستخدم أو رقم هاتف');
  String get auditNow => t('Run Audit', 'ابدأ التدقيق');
  String get scanning => t('Scanning', 'جارٍ الفحص');
  String get mockMode => t('Mock Audit Mode', 'وضع التدقيق التجريبي');
  String get mockModeDesc => t(
      'Simulated data — full flow testable without API keys or network',
      'بيانات محاكاة — اختبار كامل دون مفاتيح API أو اتصال بالشبكة');
  String get simulatedBadge => t('SIMULATED', 'محاكاة');
  String get liveBadge => t('LIVE', 'مباشر');
  String get riskScore => t('Exposure Risk Score', 'درجة خطر التعرض');
  String get tierSafe => t('Safe', 'آمن');
  String get tierLow => t('Low', 'منخفض');
  String get tierModerate => t('Moderate', 'متوسط');
  String get tierCritical => t('Critical', 'حرج');
  String get exposureBreakdown => t('Exposure Breakdown', 'تفصيل البيانات المُعرّضة');
  String get breachTimeline => t('Breach Timeline', 'الخط الزمني للتسريبات');
  String get accountsFound => t('Public Accounts Found', 'الحسابات العامة المكتشفة');
  String get remediation => t('Remediation Plan', 'خطة المعالجة');
  String get exportTitle => t('Exposure Report', 'تقرير التعرض');
  String get exportPdf => t('PDF Report', 'تقرير PDF');
  String get exportMd => t('Markdown Report', 'تقرير Markdown');
  String get copyMd => t('Copy Markdown', 'نسخ Markdown');
  String get copied => t('Copied to clipboard', 'تم النسخ إلى الحافظة');
  String get savedTo => t('Saved to', 'تم الحفظ في');
  String get passwordCheck => t('Password Exposure Check', 'فحص تعرض كلمة المرور');
  String get passwordHint => t(
      'Type a password to test — it never leaves this device (k-Anonymity)',
      'اكتب كلمة مرور للفحص — لا تغادر جهازك أبدًا (k-Anonymity)');
  String get check => t('Check', 'افحص');
  String get pwned => t('PWNED', 'مُخترقة');
  String get notPwned => t('Not found in known breaches', 'غير موجودة في التسريبات المعروفة');
  String get seenTimes => t('seen', 'ظهرت');
  String get timesSuffix => t('times in breach corpora', 'مرة في قواعد التسريبات');
  String get kAnonNote => t(
      'Only the first 5 characters of the local SHA-1 hash are sent. Matching happens on-device.',
      'يتم إرسال أول 5 أحرف فقط من تجزئة SHA-1 المحلية. تتم المطابقة على الجهاز.');
  String get hibpKey => t('HIBP API Key (optional, in-memory only)', 'مفتاح HIBP API (اختياري، يبقى في الذاكرة فقط)');
  String get hibpKeyHint => t(
      'Paste a personal key from haveibeenpwned.com/API/Key to enable live email breach lookup',
      'الصق مفتاحك الشخصي من haveibeenpwned.com/API/Key لتفعيل فحص تسريبات البريد مباشرة');
  String get identity => t('Audited identity', 'الهوية قيد التدقيق');
  String get breaches => t('breaches', 'تسريب');
  String get platforms => t('platforms', 'منصة');
  String get checked => t('checked', 'تم فحصها');
  String get accountsAffected => t('accounts affected', 'حساب متأثر');
  String get verified => t('Verified breach', 'تسريب موثّق');
  String get unverified => t('Unverified', 'غير موثّق');
  String get sensitive => t('SENSITIVE', 'حساس');
  String get exposed => t('EXPOSED', 'مُسرّب');
  String get notExposed => t('Not exposed', 'غير مُسرّب');
  String get breachComponent => t('Breach component', 'مكوّن التسريبات');
  String get platformPenalty => t('Platforms penalty', 'عقوبة المنصات');
  String get passwordPenalty => t('Password penalty', 'عقوبة كلمة المرور');
  String get stageClassify => t('Classifying input & arming privacy filter', 'تصنيف الإدخال وتفعيل مرشح الخصوصية');
  String get stageBreaches => t('Querying breach corpora', 'استعلام قواعد بيانات التسريبات');
  String get stagePlatforms => t('Sweeping 60 platforms for this username', 'مسح 60 منصة بحثًا عن اسم المستخدم');
  String get stageRisk => t('Computing social-engineering threat score', 'حساب درجة تهديد الهندسة الاجتماعية');
  String get stagePlan => t('Building remediation plan', 'بناء خطة المعالجة');
  String get noKeyNotice => t(
      'Breach lookup skipped: add a personal HIBP API key below, or build with --dart-define=HIBP_API_KEY=... Username recon and the password check need no key.',
      'تم تخطي فحص التسريبات: أضف مفتاح HIBP API الشخصي أدناه، أو ابنِ التطبيق مع --dart-define=HIBP_API_KEY=... فحص أسماء المستخدمين وكلمات المرور لا يحتاج إلى مفتاح.');
  String get privacyNote => t(
      'Zero custom servers · Zero storage · Zero tracking. Requests go directly from this device to HIBP and to each platform over TLS.',
      'لا خوادم وسيطة · لا تخزين · لا تتبّع. تنتقل الطلبات من هذا الجهاز مباشرة إلى HIBP وإلى كل منصة عبر TLS.');
  String get usernameMethodNote => t(
      'Usernames are not unique identities — treat each hit as an indicator and verify manually.',
      'أسماء المستخدمين ليست هويات فريدة — تعامل مع كل نتيجة كمؤشر يستلزم التحقق اليدوي.');
  String get reliability => t('reliability', 'الموثوقية');
  String get minutes => t('min', 'دقيقة');
  String get settings => t('Audit Settings', 'إعدادات التدقيق');
  String get language => t('Language', 'اللغة');
  String get enterSomething => t('Enter an email, username or phone number first', 'أدخل بريدًا أو اسم مستخدم أو رقم هاتف أولًا');
  String get unknownInput => t('Could not classify this input', 'تعذّر تصنيف هذا الإدخال');
  String get errorGeneric => t('Something went wrong during the audit', 'حدث خطأ أثناء التدقيق');
  String get newAudit => t('New Audit', 'تدقيق جديد');
  String get inputEmail => t('Email address', 'بريد إلكتروني');
  String get inputUsername => t('Username', 'اسم مستخدم');
  String get inputPhone => t('Phone number', 'رقم هاتف');
  String get radarIdle => t('Your digital shadow, measured.', 'ظلّك الرقمي، بالأرقام.');
  String get radarIdleSub => t(
      'Breaches, leaked data types and public accounts — fused into one social-engineering threat score.',
      'التسريبات وأنواع البيانات المُسرّبة والحسابات العامة — مدمجة في درجة تهديد واحدة للهندسة الاجتماعية.');
  String get pdfLangNote => t(
      'PDF is generated in English (standard PDF fonts cannot shape Arabic). The Markdown export is fully bilingual.',
      'يتم إنشاء PDF بالإنجليزية (خطوط PDF القياسية لا تدعم تشكيل العربية). تصدير Markdown ثنائي اللغة بالكامل.');
  String get priorityCritical => t('CRITICAL', 'حرج');
  String get priorityHigh => t('HIGH', 'عالٍ');
  String get priorityMedium => t('MEDIUM', 'متوسط');
  String get priorityLow => t('LOW', 'منخفض');

  String dataClassLabel(String dc) {
    if (!ar) return dc;
    switch (dc) {
      case 'Passwords': return 'كلمات المرور';
      case 'Email addresses': return 'عناوين البريد';
      case 'Phone numbers': return 'أرقام الهاتف';
      case 'IP addresses': return 'عناوين IP';
      case 'Physical addresses': return 'العناوين السكنية';
      case 'Dates of birth': return 'تواريخ الميلاد';
      case 'Credit cards': return 'البطاقات الائتمانية';
      case 'Social security numbers': return 'أرقام الضمان/الهوية';
      case 'Security questions and answers': return 'أسئلة الأمان';
      case 'Names': return 'الأسماء';
      case 'Usernames': return 'أسماء المستخدمين';
      case 'Geographic locations': return 'المواقع الجغرافية';
      case 'Password hints': return 'تلميحات كلمة المرور';
      case 'Genders': return 'النوع';
      case 'Social media profiles': return 'حسابات التواصل';
      default: return dc;
    }
  }

  String categoryLabel(String c) {
    if (!ar) return c;
    switch (c) {
      case 'dev': return 'تطوير';
      case 'social': return 'اجتماعي';
      case 'media': return 'وسائط';
      case 'gaming': return 'ألعاب';
      case 'creative': return 'إبداعي';
      case 'writing': return 'كتابة';
      case 'creator': return 'صنّاع محتوى';
      default: return c;
    }
  }
}
