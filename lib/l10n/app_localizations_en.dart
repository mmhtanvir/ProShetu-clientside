// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ProShetu';

  @override
  String get splashTagline => 'OFFLINE • ENCRYPTED • RESILIENT';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonNext => 'Next';

  @override
  String get commonPrevious => 'Previous';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonLoading => 'Loading';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericMessage =>
      'The action could not be completed. Check your connection and try again.';

  @override
  String get emptyGenericTitle => 'Nothing here yet';

  @override
  String get onboardingMeshTitle => 'Works When Nothing Else Does';

  @override
  String get onboardingMeshBody =>
      'Bluetooth mesh networking keeps you connected even when internet and cell towers are down. Messages hop device-to-device across your community.';

  @override
  String get onboardingEncryptionTitle => 'Military-Grade Encryption';

  @override
  String get onboardingEncryptionBody =>
      'Every message is encrypted end-to-end before it ever leaves your device. No servers. No backdoors. No one can read your communications.';

  @override
  String get onboardingMapsTitle => 'Offline Crisis Maps';

  @override
  String get onboardingMapsBody =>
      'Share safe zones, dangers, shelters, and resources with your mesh network. GPS works without internet. Your community builds the map together.';

  @override
  String get homePlaceholderTitle => 'You\'re all set';

  @override
  String get homePlaceholderMessage =>
      'The home experience is coming in the next build.';
}
