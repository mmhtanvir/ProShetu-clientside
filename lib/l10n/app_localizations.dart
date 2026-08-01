import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ProShetu'**
  String get appName;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'Secure crisis communications'**
  String get brandTagline;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE • ENCRYPTED • RESILIENT'**
  String get splashTagline;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get commonPrevious;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'The action could not be completed. Check your connection and try again.'**
  String get errorGenericMessage;

  /// No description provided for @emptyGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyGenericTitle;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get validationPhoneInvalid;

  /// No description provided for @validationPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get validationPasswordShort;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordMismatch;

  /// No description provided for @onboardingMeshTitle.
  ///
  /// In en, this message translates to:
  /// **'Works When Nothing Else Does'**
  String get onboardingMeshTitle;

  /// No description provided for @onboardingMeshBody.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth mesh networking keeps you connected even when internet and cell towers are down. Messages hop device-to-device across your community.'**
  String get onboardingMeshBody;

  /// No description provided for @onboardingEncryptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Military-Grade Encryption'**
  String get onboardingEncryptionTitle;

  /// No description provided for @onboardingEncryptionBody.
  ///
  /// In en, this message translates to:
  /// **'Every message is encrypted end-to-end before it ever leaves your device. No servers. No backdoors. No one can read your communications.'**
  String get onboardingEncryptionBody;

  /// No description provided for @onboardingMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Crisis Maps'**
  String get onboardingMapsTitle;

  /// No description provided for @onboardingMapsBody.
  ///
  /// In en, this message translates to:
  /// **'Share safe zones, dangers, shelters, and resources with your mesh network. GPS works without internet. Your community builds the map together.'**
  String get onboardingMapsBody;

  /// No description provided for @authSignupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account.'**
  String get authSignupTitle;

  /// No description provided for @authDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get authDisplayName;

  /// No description provided for @authDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your Name (Visible To Mesh Peers)'**
  String get authDisplayNameHint;

  /// No description provided for @authPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authPhoneNumber;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'01000-000000'**
  String get authPhoneHint;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'A Strong Password'**
  String get authPasswordHint;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPassword;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPasswordHint;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authLogInHere.
  ///
  /// In en, this message translates to:
  /// **'Log In here'**
  String get authLogInHere;

  /// No description provided for @authVerifyPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get authVerifyPhoneTitle;

  /// No description provided for @authOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}. Code expires in {time}.'**
  String authOtpSentTo(String phone, String time);

  /// No description provided for @authOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'The code has expired. Request a new one.'**
  String get authOtpExpired;

  /// No description provided for @authOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is not correct. Try again.'**
  String get authOtpInvalid;

  /// No description provided for @authVerifyContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get authVerifyContinue;

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get authResendCode;

  /// No description provided for @authIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get authIdentityTitle;

  /// No description provided for @authIdentityIntro.
  ///
  /// In en, this message translates to:
  /// **'To access this application, you must be a resident of Bangladesh and provide either your Birth Certificate or NID.'**
  String get authIdentityIntro;

  /// No description provided for @authNidOption.
  ///
  /// In en, this message translates to:
  /// **'National Identity Card (NID)'**
  String get authNidOption;

  /// No description provided for @authBirthCertOption.
  ///
  /// In en, this message translates to:
  /// **'Birth Certificate'**
  String get authBirthCertOption;

  /// No description provided for @authCaptureNidFront.
  ///
  /// In en, this message translates to:
  /// **'Capture the front of your National Identity Card (NID) clearly'**
  String get authCaptureNidFront;

  /// No description provided for @authCaptureNidBack.
  ///
  /// In en, this message translates to:
  /// **'Capture the back of your National Identity Card (NID) clearly'**
  String get authCaptureNidBack;

  /// No description provided for @authCaptureBirthCert.
  ///
  /// In en, this message translates to:
  /// **'Capture your Birth Certificate clearly'**
  String get authCaptureBirthCert;

  /// No description provided for @authCaptureRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get authCaptureRetake;

  /// No description provided for @authCongratsTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations'**
  String get authCongratsTitle;

  /// No description provided for @authCongratsBody.
  ///
  /// In en, this message translates to:
  /// **'Your {document} has been uploaded successfully! We will review it shortly and finalize your account.'**
  String authCongratsBody(String document);

  /// No description provided for @authLoginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get authLoginWelcome;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authSignUpHere.
  ///
  /// In en, this message translates to:
  /// **'Sign Up here'**
  String get authSignUpHere;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover Account'**
  String get authRecoveryTitle;

  /// No description provided for @authRecoveryPhoneIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter the phone number for the account you want to recover. We\'ll text you a verification code.'**
  String get authRecoveryPhoneIntro;

  /// No description provided for @authRecoveryWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'This will create a new secure identity'**
  String get authRecoveryWarningTitle;

  /// No description provided for @authRecoveryWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Recovering access on this device generates new encryption keys. Messages already stored on this device will become permanently unreadable. Everyone you\'ve messaged before will need to add you again (scan your QR code or your number) before they can reach you.'**
  String get authRecoveryWarningBody;

  /// No description provided for @authRecoveryCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I understand my message history on this device will be lost and my contacts will need to add me again'**
  String get authRecoveryCheckbox;

  /// No description provided for @authRecoveryContinue.
  ///
  /// In en, this message translates to:
  /// **'Create New Identity'**
  String get authRecoveryContinue;

  /// No description provided for @authRecoveryNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get authRecoveryNewPassword;

  /// No description provided for @authRecoveryNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'A Strong Password'**
  String get authRecoveryNewPasswordHint;

  /// No description provided for @pinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Encryption PIN'**
  String get pinTitle;

  /// No description provided for @pinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used to unlock the app, secret messages and vault'**
  String get pinSubtitle;

  /// No description provided for @pinChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a 6-digit PIN'**
  String get pinChoose;

  /// No description provided for @pinNote.
  ///
  /// In en, this message translates to:
  /// **'Establish an \"Encryption PIN\" that discreetly erases data and reveals hidden messages and vault contents.'**
  String get pinNote;

  /// No description provided for @trustedTitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted Contacts'**
  String get trustedTitle;

  /// No description provided for @trustedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add trusted contacts to enhance your security.'**
  String get trustedSubtitle;

  /// No description provided for @trustedContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Trusted Contact {number}'**
  String trustedContactLabel(String number);

  /// No description provided for @trustedContactHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Trusted Contact'**
  String get trustedContactHint;

  /// No description provided for @trustedNote.
  ///
  /// In en, this message translates to:
  /// **'To complete your profile setup, please add at least one Trusted Contact.'**
  String get trustedNote;

  /// No description provided for @trustedAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Trusted Contacts'**
  String get trustedAdd;

  /// No description provided for @authCaptureFrontLabel.
  ///
  /// In en, this message translates to:
  /// **'Front side'**
  String get authCaptureFrontLabel;

  /// No description provided for @authCaptureBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Back side'**
  String get authCaptureBackLabel;

  /// No description provided for @authCaptureDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'Document photo'**
  String get authCaptureDocumentLabel;

  /// No description provided for @authCaptureTapToCapture.
  ///
  /// In en, this message translates to:
  /// **'Tap to capture'**
  String get authCaptureTapToCapture;

  /// No description provided for @authCaptureTapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get authCaptureTapToChange;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navChats;

  /// No description provided for @navSos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get navSos;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get greetingEvening;

  /// No description provided for @dashNetworkStatus.
  ///
  /// In en, this message translates to:
  /// **'Network Status'**
  String get dashNetworkStatus;

  /// No description provided for @dashDevicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} devices'**
  String dashDevicesCount(String count);

  /// No description provided for @dashNearbyOnMesh.
  ///
  /// In en, this message translates to:
  /// **'Nearby on Mesh'**
  String get dashNearbyOnMesh;

  /// No description provided for @dashConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get dashConnect;

  /// No description provided for @meshUnknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown nearby device'**
  String get meshUnknownDevice;

  /// No description provided for @meshUnknownDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'Not yet linked to a contact'**
  String get meshUnknownDeviceHint;

  /// No description provided for @meshBluetoothOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off'**
  String get meshBluetoothOffTitle;

  /// No description provided for @meshBluetoothOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth to discover nearby ProShetu users.'**
  String get meshBluetoothOffMessage;

  /// No description provided for @meshPermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission needed'**
  String get meshPermissionDeniedTitle;

  /// No description provided for @meshPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Grant Bluetooth permission to discover nearby ProShetu users.'**
  String get meshPermissionDeniedMessage;

  /// No description provided for @meshUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth mesh unavailable'**
  String get meshUnsupportedTitle;

  /// No description provided for @meshUnsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'This device doesn\'t support Bluetooth Low Energy.'**
  String get meshUnsupportedMessage;

  /// No description provided for @meshOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get meshOpenSettings;

  /// No description provided for @meshEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No one nearby yet'**
  String get meshEmptyTitle;

  /// No description provided for @meshEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep this screen open — nearby ProShetu users will appear here.'**
  String get meshEmptyMessage;

  /// No description provided for @meshProximityVeryClose.
  ///
  /// In en, this message translates to:
  /// **'Very close'**
  String get meshProximityVeryClose;

  /// No description provided for @meshProximityNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get meshProximityNearby;

  /// No description provided for @meshProximityFar.
  ///
  /// In en, this message translates to:
  /// **'Farther away'**
  String get meshProximityFar;

  /// No description provided for @meshPeersBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} peers'**
  String meshPeersBadge(String count);

  /// No description provided for @meshScanningNear.
  ///
  /// In en, this message translates to:
  /// **'Scanning near {place}'**
  String meshScanningNear(String place);

  /// No description provided for @meshLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your location is unavailable'**
  String get meshLocationUnavailable;

  /// No description provided for @dashInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get dashInternet;

  /// No description provided for @dashGps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get dashGps;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @statusLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get statusLocked;

  /// No description provided for @dashActiveAlert.
  ///
  /// In en, this message translates to:
  /// **'Active Alert'**
  String get dashActiveAlert;

  /// No description provided for @chatsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search By Name Or Number'**
  String get chatsSearchHint;

  /// No description provided for @chatsActivePeople.
  ///
  /// In en, this message translates to:
  /// **'{count} Active People'**
  String chatsActivePeople(String count);

  /// No description provided for @chatsAll.
  ///
  /// In en, this message translates to:
  /// **'All Chats'**
  String get chatsAll;

  /// No description provided for @composerVisibleLabel.
  ///
  /// In en, this message translates to:
  /// **'Please enter a Visible message'**
  String get composerVisibleLabel;

  /// No description provided for @composerEncryptedHint.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Message Here'**
  String get composerEncryptedHint;

  /// No description provided for @commonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonSend;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'This screen arrives in an upcoming build.'**
  String get comingSoonMessage;

  /// No description provided for @sosCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a SOS Alert'**
  String get sosCreateTitle;

  /// No description provided for @sosTypeNatural.
  ///
  /// In en, this message translates to:
  /// **'Natural Disaster'**
  String get sosTypeNatural;

  /// No description provided for @sosTypeProtest.
  ///
  /// In en, this message translates to:
  /// **'Protest / Distress'**
  String get sosTypeProtest;

  /// No description provided for @sosTypeInNeed.
  ///
  /// In en, this message translates to:
  /// **'In Need'**
  String get sosTypeInNeed;

  /// No description provided for @sosTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'SOS Type'**
  String get sosTypeLabel;

  /// No description provided for @sosName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sosName;

  /// No description provided for @sosNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get sosNumber;

  /// No description provided for @sosLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get sosLocation;

  /// No description provided for @sosLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your current location'**
  String get sosLocationHint;

  /// No description provided for @sosDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sosDescription;

  /// No description provided for @sosOptionalSuffix.
  ///
  /// In en, this message translates to:
  /// **'(Optional)'**
  String get sosOptionalSuffix;

  /// No description provided for @sosDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter About The SOS'**
  String get sosDescriptionHint;

  /// No description provided for @sosLookingFor.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get sosLookingFor;

  /// No description provided for @sosLookingForHint.
  ///
  /// In en, this message translates to:
  /// **'Enter The Help You Are Looking For'**
  String get sosLookingForHint;

  /// No description provided for @sosCreate.
  ///
  /// In en, this message translates to:
  /// **'Create SOS Alert'**
  String get sosCreate;

  /// No description provided for @sosSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your SOS Alert has been successfully created! Stay safe and keep your device charged.'**
  String get sosSuccessBody;

  /// No description provided for @profileKycPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get profileKycPendingReview;

  /// No description provided for @profileVault.
  ///
  /// In en, this message translates to:
  /// **'Blackbox Vault'**
  String get profileVault;

  /// No description provided for @profileSecuritySection.
  ///
  /// In en, this message translates to:
  /// **'Security & Identity'**
  String get profileSecuritySection;

  /// No description provided for @profileEncryptionKeys.
  ///
  /// In en, this message translates to:
  /// **'Encryption Keys'**
  String get profileEncryptionKeys;

  /// No description provided for @profileTrustedDevices.
  ///
  /// In en, this message translates to:
  /// **'Trusted Devices'**
  String get profileTrustedDevices;

  /// No description provided for @profileDevicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} devices'**
  String profileDevicesCount(String count);

  /// No description provided for @profileActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get profileActivityLog;

  /// No description provided for @profilePrefsSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePrefsSection;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileAppearance;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get profileDeleteConfirmTitle;

  /// No description provided for @profileDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your account, keys, and vault contents from this device.'**
  String get profileDeleteConfirmBody;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @vaultEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your encryption PIN'**
  String get vaultEnterPin;

  /// No description provided for @vaultWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Try again.'**
  String get vaultWrongPin;

  /// No description provided for @vaultToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get vaultToday;

  /// No description provided for @vaultEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your vault is empty'**
  String get vaultEmptyTitle;

  /// No description provided for @vaultEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Encrypted photos and files you save here will appear in this space.'**
  String get vaultEmptyMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
