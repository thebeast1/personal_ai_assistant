import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/utils/app_constants.dart';

/// UI text in English and Arabic, picked from the app's current locale.
class AppStrings {
  const AppStrings._(this.isArabic);

  final bool isArabic;

  static AppStrings of(BuildContext context) =>
      AppStrings._(Localizations.localeOf(context).languageCode == 'ar');

  String _t(String en, String ar) => isArabic ? ar : en;

  /// The assistant's name: Khadeja / خديجة.
  String get assistantName =>
      _t(AppConstants.assistantNameEn, AppConstants.assistantNameAr);

  /// Label for the button that switches to the *other* language.
  String get switchLanguage => _t('العربية', 'English');
  String get switchLanguageTooltip =>
      _t('Switch to Arabic', 'التبديل إلى الإنجليزية');

  // Loading screen
  String get preparingDownload => _t('Preparing download…', 'جارٍ تحضير التنزيل…');
  String get downloadingModel => _t('Downloading model…', 'جارٍ تنزيل النموذج…');
  String get finishingUp => _t('Finishing up…', 'اللمسات الأخيرة…');
  String get worksOffline => _t('Works offline', 'يعمل دون إنترنت');
  String get private => _t('Private', 'خاص');
  String get onDevice => _t('On-device', 'على جهازك');
  String get oneTimeDownload => _t(
    'This is a one-time download. Keep the app open until it finishes.',
    'يتم التنزيل مرة واحدة فقط. أبقِ التطبيق مفتوحًا حتى ينتهي.',
  );

  // Chat
  String get messageHint => _t('Message', 'اكتب رسالة');
  String get send => _t('Send', 'إرسال');
  String get assistantTyping => _t('Assistant is typing', 'المساعد يكتب');
  String get removeImage => _t('Remove image', 'إزالة الصورة');
  String get startRecording => _t('Record voice message', 'تسجيل رسالة صوتية');
  String get stopRecording => _t('Stop recording', 'إيقاف التسجيل');
  String get recording => _t('Recording…', 'جارٍ التسجيل…');
  String get voiceMessage => _t('Voice message', 'رسالة صوتية');
  String get deleteRecording => _t('Delete recording', 'حذف التسجيل');

  // Clear conversation
  String get clearChat => _t('Clear conversation', 'مسح المحادثة');
  String get clearChatTitle => _t('Clear conversation?', 'مسح المحادثة؟');
  String get clearChatMessage => _t(
    'All messages will be deleted and a new session will start. This can\'t be undone.',
    'سيتم حذف جميع الرسائل وبدء جلسة جديدة. لا يمكن التراجع عن ذلك.',
  );
  String get cancel => _t('Cancel', 'إلغاء');
  String get clear => _t('Clear', 'مسح');

  // Empty chat
  String get emptyChatTitle => _t("Hi, I'm $assistantName", 'مرحبًا، أنا $assistantName');
  String get emptyChatSubtitle => _t(
    'How can I help you today? I run privately on your device.',
    'كيف يمكنني مساعدتك اليوم؟ أعمل بخصوصية على جهازك.',
  );
  String get suggestWhatCanYouDo =>
      _t('What can you do?', 'ماذا يمكنك أن تفعل؟');
  String get suggestExplain => _t(
    'Explain how the internet works in simple words',
    'اشرح كيف يعمل الإنترنت بكلمات بسيطة',
  );
  String get suggestWrite => _t(
    'Write a short, friendly birthday message for a friend',
    'اكتب رسالة تهنئة قصيرة ولطيفة بعيد ميلاد صديق',
  );
  String get suggestWorkout => _t(
    'Give me a 20-minute home workout with no equipment',
    'اقترح عليّ تمرينًا منزليًا مدته ٢٠ دقيقة بدون أدوات',
  );
  String get suggestDinner => _t(
    'Suggest 5 quick and easy dinner ideas',
    'اقترح ٥ أفكار سريعة وسهلة للعشاء',
  );
}
