// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'প্রশেতু';

  @override
  String get splashTagline => 'OFFLINE • ENCRYPTED • RESILIENT';

  @override
  String get commonRetry => 'আবার চেষ্টা করুন';

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get commonConfirm => 'নিশ্চিত করুন';

  @override
  String get commonLoading => 'লোড হচ্ছে';

  @override
  String get errorGenericTitle => 'কিছু একটা সমস্যা হয়েছে';

  @override
  String get errorGenericMessage =>
      'কাজটি সম্পন্ন করা যায়নি। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get emptyGenericTitle => 'এখনও কিছু নেই';
}
