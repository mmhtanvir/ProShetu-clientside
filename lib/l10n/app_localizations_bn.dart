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
  String get brandTagline => 'নিরাপদ সংকটকালীন যোগাযোগ';

  @override
  String get splashTagline => 'OFFLINE • ENCRYPTED • RESILIENT';

  @override
  String get commonRetry => 'আবার চেষ্টা করুন';

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get commonConfirm => 'নিশ্চিত করুন';

  @override
  String get commonContinue => 'চালিয়ে যান';

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
  String get validationRequired => 'আবশ্যক';

  @override
  String get validationPhoneInvalid => 'সঠিক ফোন নম্বর দিন';

  @override
  String get validationPasswordShort => 'অন্তত ৮টি অক্ষর ব্যবহার করুন';

  @override
  String get validationPasswordMismatch => 'পাসওয়ার্ড মিলছে না';

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
  String get authSignupTitle => 'অ্যাকাউন্ট তৈরি করুন।';

  @override
  String get authDisplayName => 'প্রদর্শিত নাম';

  @override
  String get authDisplayNameHint => 'আপনার নাম (মেশ পিয়ারদের কাছে দৃশ্যমান)';

  @override
  String get authPhoneNumber => 'ফোন নম্বর';

  @override
  String get authPhoneHint => '+৮৮ ০১০০০-০০০০০০';

  @override
  String get authPassword => 'পাসওয়ার্ড';

  @override
  String get authPasswordHint => 'একটি শক্তিশালী পাসওয়ার্ড';

  @override
  String get authConfirmPassword => 'পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get authConfirmPasswordHint => 'পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get authSignUp => 'সাইন আপ';

  @override
  String get authHaveAccount => 'ইতিমধ্যে অ্যাকাউন্ট আছে?';

  @override
  String get authLogInHere => 'লগ ইন করুন';

  @override
  String get authVerifyPhoneTitle => 'ফোন যাচাই';

  @override
  String authOtpSentTo(String phone, String time) {
    return 'আমরা $phone নম্বরে ৬-সংখ্যার কোড পাঠিয়েছি। কোডের মেয়াদ $time।';
  }

  @override
  String get authOtpExpired => 'কোডের মেয়াদ শেষ। নতুন কোড নিন।';

  @override
  String get authOtpInvalid => 'কোডটি সঠিক নয়। আবার চেষ্টা করুন।';

  @override
  String get authVerifyContinue => 'যাচাই করে এগিয়ে যান';

  @override
  String get authResendCode => 'কোড আবার পাঠান';

  @override
  String get authIdentityTitle => 'পরিচয় যাচাই';

  @override
  String get authIdentityIntro =>
      'এই অ্যাপ ব্যবহার করতে আপনাকে বাংলাদেশের বাসিন্দা হতে হবে এবং জন্ম নিবন্ধন সনদ অথবা NID দিতে হবে।';

  @override
  String get authNidOption => 'জাতীয় পরিচয়পত্র (NID)';

  @override
  String get authBirthCertOption => 'জন্ম নিবন্ধন সনদ';

  @override
  String get authCaptureNidFront => 'আপনার NID-এর সামনের দিক স্পষ্টভাবে তুলুন';

  @override
  String get authCaptureNidBack => 'আপনার NID-এর পেছনের দিক স্পষ্টভাবে তুলুন';

  @override
  String get authCaptureBirthCert => 'আপনার জন্ম নিবন্ধন সনদ স্পষ্টভাবে তুলুন';

  @override
  String get authCaptureRetake => 'আবার তুলুন';

  @override
  String get authCongratsTitle => 'অভিনন্দন';

  @override
  String authCongratsBody(String document) {
    return 'আপনার $document সফলভাবে আপলোড হয়েছে! আমরা শীঘ্রই পর্যালোচনা করে আপনার অ্যাকাউন্ট চূড়ান্ত করব।';
  }

  @override
  String get authLoginWelcome => 'আবার স্বাগতম!';

  @override
  String get authLogin => 'লগইন';

  @override
  String get authNoAccount => 'অ্যাকাউন্ট নেই?';

  @override
  String get authSignUpHere => 'সাইন আপ করুন';

  @override
  String get pinTitle => 'এনক্রিপশন পিন সেট করুন';

  @override
  String get pinSubtitle => 'অ্যাপ, গোপন বার্তা ও ভল্ট খুলতে ব্যবহৃত হয়';

  @override
  String get pinChoose => '৬-সংখ্যার একটি পিন বেছে নিন';

  @override
  String get pinNote =>
      'একটি \"এনক্রিপশন পিন\" সেট করুন যা গোপনে ডেটা মুছে ফেলে এবং লুকানো বার্তা ও ভল্ট প্রকাশ করে।';

  @override
  String get trustedTitle => 'বিশ্বস্ত পরিচিতি';

  @override
  String get trustedSubtitle => 'নিরাপত্তা বাড়াতে বিশ্বস্ত পরিচিতি যোগ করুন।';

  @override
  String trustedContactLabel(String number) {
    return 'বিশ্বস্ত পরিচিতি $number';
  }

  @override
  String get trustedContactHint => 'আপনার বিশ্বস্ত পরিচিতি লিখুন';

  @override
  String get trustedNote =>
      'প্রোফাইল সেটআপ সম্পূর্ণ করতে অন্তত একটি বিশ্বস্ত পরিচিতি যোগ করুন।';

  @override
  String get trustedAdd => 'বিশ্বস্ত পরিচিতি যোগ করুন';

  @override
  String get homePlaceholderTitle => 'সব প্রস্তুত';

  @override
  String get homePlaceholderMessage => 'হোম স্ক্রিন পরবর্তী বিল্ডে আসছে।';

  @override
  String get authCaptureFrontLabel => 'সামনের দিক';

  @override
  String get authCaptureBackLabel => 'পেছনের দিক';

  @override
  String get authCaptureDocumentLabel => 'নথির ছবি';

  @override
  String get authCaptureTapToCapture => 'ছবি তুলতে চাপুন';

  @override
  String get authCaptureTapToChange => 'পরিবর্তন করতে চাপুন';
}
