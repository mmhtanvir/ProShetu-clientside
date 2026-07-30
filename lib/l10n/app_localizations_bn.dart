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
  String get commonNext => 'পরবর্তী';

  @override
  String get commonPrevious => 'পূর্ববর্তী';

  @override
  String get commonSkip => 'এড়িয়ে যান';

  @override
  String get commonLoading => 'লোড হচ্ছে';

  @override
  String get errorGenericTitle => 'কিছু একটা সমস্যা হয়েছে';

  @override
  String get errorGenericMessage =>
      'কাজটি সম্পন্ন করা যায়নি। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get emptyGenericTitle => 'এখনও কিছু নেই';

  @override
  String get onboardingMeshTitle => 'যখন আর কিছুই কাজ করে না';

  @override
  String get onboardingMeshBody =>
      'ইন্টারনেট ও মোবাইল নেটওয়ার্ক বন্ধ থাকলেও ব্লুটুথ মেশ নেটওয়ার্ক আপনাকে সংযুক্ত রাখে। বার্তা এক ডিভাইস থেকে আরেক ডিভাইসে পৌঁছে যায়।';

  @override
  String get onboardingEncryptionTitle => 'সামরিক-মানের এনক্রিপশন';

  @override
  String get onboardingEncryptionBody =>
      'প্রতিটি বার্তা ডিভাইস ছাড়ার আগেই এন্ড-টু-এন্ড এনক্রিপ্ট হয়। কোনো সার্ভার নেই। কোনো ব্যাকডোর নেই। কেউ আপনার যোগাযোগ পড়তে পারবে না।';

  @override
  String get onboardingMapsTitle => 'অফলাইন ক্রাইসিস ম্যাপ';

  @override
  String get onboardingMapsBody =>
      'নিরাপদ এলাকা, বিপদ, আশ্রয়কেন্দ্র ও সম্পদের তথ্য মেশ নেটওয়ার্কে শেয়ার করুন। ইন্টারনেট ছাড়াই GPS কাজ করে। কমিউনিটি মিলে ম্যাপ তৈরি করে।';

  @override
  String get homePlaceholderTitle => 'সব প্রস্তুত';

  @override
  String get homePlaceholderMessage => 'হোম স্ক্রিন পরবর্তী বিল্ডে আসছে।';
}
