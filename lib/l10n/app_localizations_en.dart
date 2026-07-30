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
  String get brandTagline => 'Secure crisis communications';

  @override
  String get splashTagline => 'OFFLINE • ENCRYPTED • RESILIENT';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonContinue => 'Continue';

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
  String get validationRequired => 'Required';

  @override
  String get validationPhoneInvalid => 'Enter a valid phone number';

  @override
  String get validationPasswordShort => 'Use at least 8 characters';

  @override
  String get validationPasswordMismatch => 'Passwords do not match';

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
  String get authSignupTitle => 'Create Account.';

  @override
  String get authDisplayName => 'Display Name';

  @override
  String get authDisplayNameHint => 'Your Name (Visible To Mesh Peers)';

  @override
  String get authPhoneNumber => 'Phone Number';

  @override
  String get authPhoneHint => '+88 01000-000000';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'A Strong Password';

  @override
  String get authConfirmPassword => 'Confirm Password';

  @override
  String get authConfirmPasswordHint => 'Confirm Password';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authLogInHere => 'Log In here';

  @override
  String get authVerifyPhoneTitle => 'Verify Phone';

  @override
  String authOtpSentTo(String phone, String time) {
    return 'We sent a 6-digit code to $phone. Code expires in $time.';
  }

  @override
  String get authOtpExpired => 'The code has expired. Request a new one.';

  @override
  String get authOtpInvalid => 'That code is not correct. Try again.';

  @override
  String get authVerifyContinue => 'Verify & Continue';

  @override
  String get authResendCode => 'Resend Code';

  @override
  String get authIdentityTitle => 'Identity Verification';

  @override
  String get authIdentityIntro =>
      'To access this application, you must be a resident of Bangladesh and provide either your Birth Certificate or NID.';

  @override
  String get authNidOption => 'National Identity Card (NID)';

  @override
  String get authBirthCertOption => 'Birth Certificate';

  @override
  String get authCaptureNidFront =>
      'Capture the front of your National Identity Card (NID) clearly';

  @override
  String get authCaptureNidBack =>
      'Capture the back of your National Identity Card (NID) clearly';

  @override
  String get authCaptureBirthCert => 'Capture your Birth Certificate clearly';

  @override
  String get authCaptureRetake => 'Retake';

  @override
  String get authCongratsTitle => 'Congratulations';

  @override
  String authCongratsBody(String document) {
    return 'Your $document has been uploaded successfully! We will review it shortly and finalize your account.';
  }

  @override
  String get authLoginWelcome => 'Welcome Back!';

  @override
  String get authLogin => 'Login';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authSignUpHere => 'Sign Up here';

  @override
  String get pinTitle => 'Set Encryption PIN';

  @override
  String get pinSubtitle => 'Used to unlock the app, secret messages and vault';

  @override
  String get pinChoose => 'Choose a 6-digit PIN';

  @override
  String get pinNote =>
      'Establish an \"Encryption PIN\" that discreetly erases data and reveals hidden messages and vault contents.';

  @override
  String get trustedTitle => 'Trusted Contacts';

  @override
  String get trustedSubtitle =>
      'Add trusted contacts to enhance your security.';

  @override
  String trustedContactLabel(String number) {
    return 'Trusted Contact $number';
  }

  @override
  String get trustedContactHint => 'Enter Your Trusted Contact';

  @override
  String get trustedNote =>
      'To complete your profile setup, please add at least one Trusted Contact.';

  @override
  String get trustedAdd => 'Add Trusted Contacts';

  @override
  String get homePlaceholderTitle => 'You\'re all set';

  @override
  String get homePlaceholderMessage =>
      'The home experience is coming in the next build.';

  @override
  String get authCaptureFrontLabel => 'Front side';

  @override
  String get authCaptureBackLabel => 'Back side';

  @override
  String get authCaptureDocumentLabel => 'Document photo';

  @override
  String get authCaptureTapToCapture => 'Tap to capture';

  @override
  String get authCaptureTapToChange => 'Tap to change';

  @override
  String get navHome => 'Home';

  @override
  String get navChats => 'Chats';

  @override
  String get navSos => 'SOS';

  @override
  String get navMap => 'Map';

  @override
  String get navProfile => 'Profile';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

  @override
  String get dashNetworkStatus => 'Network Status';

  @override
  String dashDevicesCount(String count) {
    return '$count devices';
  }

  @override
  String get dashNearbyOnMesh => 'Nearby on Mesh';

  @override
  String get dashConnect => 'Connect';

  @override
  String get dashInternet => 'Internet';

  @override
  String get dashGps => 'GPS';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusLocked => 'Locked';

  @override
  String get dashActiveAlert => 'Active Alert';

  @override
  String get chatsSearchHint => 'Search By Name Or Number';

  @override
  String chatsActivePeople(String count) {
    return '$count Active People';
  }

  @override
  String get chatsAll => 'All Chats';

  @override
  String get composerVisibleLabel => 'Please enter a Visible message';

  @override
  String get composerEncryptedHint => 'Encrypted Message Here';

  @override
  String get commonSend => 'Send';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonMessage => 'This screen arrives in an upcoming build.';

  @override
  String get sosCreateTitle => 'Create a SOS Alert';

  @override
  String get sosTypeNatural => 'Natural Disaster';

  @override
  String get sosTypeProtest => 'Protest / Distress';

  @override
  String get sosTypeInNeed => 'In Need';

  @override
  String get sosTypeLabel => 'SOS Type';

  @override
  String get sosName => 'Name';

  @override
  String get sosNumber => 'Number';

  @override
  String get sosLocation => 'Location';

  @override
  String get sosDescription => 'Description';

  @override
  String get sosOptionalSuffix => '(Optional)';

  @override
  String get sosDescriptionHint => 'Enter About The SOS';

  @override
  String get sosLookingFor => 'What are you looking for?';

  @override
  String get sosLookingForHint => 'Enter The Help You Are Looking For';

  @override
  String get sosCreate => 'Create SOS Alert';

  @override
  String get sosSuccessBody =>
      'Your SOS Alert has been successfully created! Stay safe and keep your device charged.';

  @override
  String get profileKycVerified => 'KYC Verified';

  @override
  String get profileVault => 'Blackbox Vault';

  @override
  String get profileSecuritySection => 'Security & Identity';

  @override
  String get profileEncryptionKeys => 'Encryption Keys';

  @override
  String get profileTrustedDevices => 'Trusted Devices';

  @override
  String profileDevicesCount(String count) {
    return '$count devices';
  }

  @override
  String get profileActivityLog => 'Activity Log';

  @override
  String get profilePrefsSection => 'Preferences';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileAppearance => 'Appearance';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileDeleteAccount => 'Delete Account';

  @override
  String get profileDeleteConfirmTitle => 'Delete account?';

  @override
  String get profileDeleteConfirmBody =>
      'This permanently removes your account, keys, and vault contents from this device.';

  @override
  String get commonDelete => 'Delete';

  @override
  String get vaultEnterPin => 'Enter your encryption PIN';

  @override
  String get vaultWrongPin => 'Incorrect PIN. Try again.';

  @override
  String get vaultToday => 'Today';

  @override
  String get commonBack => 'Back';

  @override
  String get mapDetailsCreatedBy => 'Created By';

  @override
  String get mapDetailsLookingFor => 'Looking For';

  @override
  String get mapDetailsCopyNumber => 'Copy number';

  @override
  String get mapNumberCopied => 'Number copied';
}
