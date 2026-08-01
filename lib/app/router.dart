import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/connectivity/presentation/screens/dashboard_screen.dart';
import '../features/connectivity/presentation/screens/nearby_mesh_screen.dart';
import '../features/coordination/presentation/screens/map_screen.dart';
import '../features/messaging/presentation/screens/add_by_number_screen.dart';
import '../features/messaging/presentation/screens/chats_screen.dart';
import '../features/messaging/presentation/screens/conversation_screen.dart';
import '../features/messaging/presentation/screens/my_qr_screen.dart';
import '../features/messaging/presentation/screens/scan_qr_screen.dart';
import '../features/onboarding/presentation/screens/identity_capture_screen.dart';
import '../features/onboarding/presentation/screens/identity_choice_screen.dart';
import '../features/onboarding/presentation/screens/identity_success_screen.dart';
import '../features/onboarding/presentation/screens/login_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/onboarding/presentation/screens/recover_account_screen.dart';
import '../features/onboarding/presentation/screens/recovery_confirm_screen.dart';
import '../features/onboarding/presentation/screens/recovery_verify_screen.dart';
import '../features/onboarding/presentation/screens/set_pin_screen.dart';
import '../features/onboarding/presentation/screens/signup_screen.dart';
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/trusted_contacts_screen.dart';
import '../features/onboarding/presentation/screens/verify_phone_screen.dart';
import '../features/panic/presentation/screens/sos_form_screen.dart';
import '../features/panic/presentation/screens/sos_success_screen.dart';
import '../features/panic/presentation/screens/sos_type_screen.dart';
import '../features/settings/presentation/screens/vault_gallery_screen.dart';
import '../features/settings/presentation/screens/vault_lock_screen.dart';
import '../features/settings/presentation/screens/profile_screen.dart';
import '../features/voice/presentation/screens/call_screen.dart';
import 'shell.dart';

/// Route names & paths in one place. Screens navigate by name, never
/// by raw string, so paths can evolve safely.
abstract final class AppRoutes {
  static const String splash = 'splash';
  static const String splashPath = '/';

  static const String onboarding = 'onboarding';
  static const String onboardingPath = '/onboarding';

  static const String signup = 'signup';
  static const String signupPath = '/signup';
  static const String verifyPhone = 'verify-phone';
  static const String verifyPhonePath = '/signup/verify-phone';
  static const String identityChoice = 'identity-choice';
  static const String identityChoicePath = '/signup/identity';
  static const String identityCapture = 'identity-capture';
  static const String identityCapturePath = '/signup/identity/capture';
  static const String identitySuccess = 'identity-success';
  static const String identitySuccessPath = '/signup/identity/success';

  static const String login = 'login';
  static const String loginPath = '/login';
  static const String recoverAccount = 'recover-account';
  static const String recoverAccountPath = '/recover';
  static const String recoveryConfirm = 'recovery-confirm';
  static const String recoveryConfirmPath = '/recover/confirm';
  static const String recoveryVerify = 'recovery-verify';
  static const String recoveryVerifyPath = '/recover/verify';
  static const String setPin = 'set-pin';
  static const String setPinPath = '/setup/pin';
  static const String trustedContacts = 'trusted-contacts';
  static const String trustedContactsPath = '/setup/trusted-contacts';

  // Shell tabs.
  static const String home = 'home';
  static const String homePath = '/home';
  static const String chats = 'chats';
  static const String chatsPath = '/chats';
  static const String map = 'map';
  static const String mapPath = '/map';
  static const String profile = 'profile';
  static const String profilePath = '/profile';

  // Above-shell screens.
  static const String nearbyMesh = 'nearby-mesh';
  static const String nearbyMeshPath = '/home/nearby';
  static const String conversation = 'conversation';
  static const String conversationPath = '/chats/:id';
  static const String sos = 'sos';
  static const String sosPath = '/sos';
  static const String sosForm = 'sos-form';
  static const String sosFormPath = '/sos/form';
  static const String sosSuccess = 'sos-success';
  static const String sosSuccessPath = '/sos/success';
  static const String vaultLock = 'vault-lock';
  static const String vaultLockPath = '/profile/vault';
  static const String vaultGallery = 'vault-gallery';
  static const String vaultGalleryPath = '/profile/vault/gallery';
  static const String call = 'call';
  static const String callPath = '/call';
  static const String myQr = 'my-qr';
  static const String myQrPath = '/pairing/my-qr';
  static const String scanQr = 'scan-qr';
  static const String scanQrPath = '/pairing/scan-qr';
  static const String addByNumber = 'add-by-number';
  static const String addByNumberPath = '/pairing/add-by-number';

  // Reserved.
  static const String lock = 'lock';
  static const String lockPath = '/lock';
}

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

/// Router provider. Riverpod-owned so redirects can later read auth,
/// lock and wipe state reactively.
final routerProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splashPath,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingPath,
        name: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupPath,
        name: AppRoutes.signup,
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyPhonePath,
        name: AppRoutes.verifyPhone,
        builder: (BuildContext context, GoRouterState state) =>
            VerifyPhoneScreen(phone: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: AppRoutes.identityChoicePath,
        name: AppRoutes.identityChoice,
        builder: (_, __) => const IdentityChoiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.identityCapturePath,
        name: AppRoutes.identityCapture,
        builder: (_, __) => const IdentityCaptureScreen(),
      ),
      GoRoute(
        path: AppRoutes.identitySuccessPath,
        name: AppRoutes.identitySuccess,
        builder: (_, __) => const IdentitySuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.recoverAccountPath,
        name: AppRoutes.recoverAccount,
        builder: (_, __) => const RecoverAccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.recoveryConfirmPath,
        name: AppRoutes.recoveryConfirm,
        builder: (BuildContext context, GoRouterState state) =>
            RecoveryConfirmScreen(phone: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: AppRoutes.recoveryVerifyPath,
        name: AppRoutes.recoveryVerify,
        builder: (BuildContext context, GoRouterState state) =>
            RecoveryVerifyScreen(phone: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: AppRoutes.setPinPath,
        name: AppRoutes.setPin,
        builder: (_, __) => const SetPinScreen(),
      ),
      GoRoute(
        path: AppRoutes.trustedContactsPath,
        name: AppRoutes.trustedContacts,
        builder: (_, __) => const TrustedContactsScreen(),
      ),

      // ── Tab shell ────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, StatefulNavigationShell shell) =>
            AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.homePath,
              name: AppRoutes.home,
              builder: (_, __) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'nearby',
                  name: AppRoutes.nearbyMesh,
                  parentNavigatorKey: _rootKey, // covers the bottom bar
                  builder: (_, __) => const NearbyMeshScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.chatsPath,
              name: AppRoutes.chats,
              builder: (_, __) => const ChatsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: AppRoutes.conversation,
                  parentNavigatorKey: _rootKey,
                  builder: (BuildContext context, GoRouterState state) =>
                      ConversationScreen(
                    chatId: state.pathParameters['id'] ?? '',
                    peerName: state.extra as String? ?? '',
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.mapPath,
              name: AppRoutes.map,
              builder: (_, __) => const MapScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profilePath,
              name: AppRoutes.profile,
              builder: (_, __) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      GoRoute(
        path: AppRoutes.sosPath,
        name: AppRoutes.sos,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SosTypeScreen(),
      ),
      GoRoute(
        path: AppRoutes.sosFormPath,
        name: AppRoutes.sosForm,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SosFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.sosSuccessPath,
        name: AppRoutes.sosSuccess,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SosSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.vaultLockPath,
        name: AppRoutes.vaultLock,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const VaultLockScreen(),
      ),
      GoRoute(
        path: AppRoutes.vaultGalleryPath,
        name: AppRoutes.vaultGallery,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const VaultGalleryScreen(),
      ),
      GoRoute(
        path: AppRoutes.callPath,
        name: AppRoutes.call,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CallScreen(),
      ),
      GoRoute(
        path: AppRoutes.myQrPath,
        name: AppRoutes.myQr,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const MyQrScreen(),
      ),
      GoRoute(
        path: AppRoutes.scanQrPath,
        name: AppRoutes.scanQr,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ScanQrScreen(),
      ),
      GoRoute(
        path: AppRoutes.addByNumberPath,
        name: AppRoutes.addByNumber,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AddByNumberScreen(),
      ),
    ],
    // redirect: hook point for auth / lock-screen / emergency-wipe
    // guards. Left inert until session state exists.
  );
});
