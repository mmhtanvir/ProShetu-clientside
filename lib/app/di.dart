import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_config.dart';
import '../infrastructure/transport/api_client.dart';
import '../infrastructure/transport/push_socket.dart';
import '../infrastructure/transport/signing_interceptor.dart';

/// Composition root.
///
/// Riverpod providers *are* the DI container: everything below is
/// lazily created on first read and disposable in tests via overrides.

/// True once main.dart's Firebase.initializeApp() call has actually
/// succeeded. FCM (fcm_service.dart) is real but genuinely optional
/// infrastructure — this deployment may not have a Firebase project's
/// google-services.json/GoogleService-Info.plist in place yet — so
/// every FCM call site must check this rather than assume Firebase is
/// ready, the same way pushSocketProvider callers already tolerate
/// AppConfig.wsBaseUrl being unset. Overridden in main.dart's
/// ProviderScope once the real value is known.
final firebaseReadyProvider = Provider<bool>((Ref ref) => false);

/// Secure at-rest key/value storage (Android Keystore / iOS Keychain).
final secureStorageProvider = Provider<FlutterSecureStorage>((Ref ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );
});

BaseOptions _baseOptions() => BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    );

/// A Dio instance with NO interceptors — used only to fetch
/// `/v1/challenge`, so the signing interceptor doesn't try to sign
/// the request that fetches the thing it needs to sign.
final _bareDioProvider = Provider<Dio>((Ref ref) => Dio(_baseOptions()));

/// Configured HTTP client. Base URL comes exclusively from
/// [AppConfig] — never hardcode endpoints. Deliberately left
/// unconfigured (`API_BASE_URL` unset) until a deployment target is
/// chosen; every request will fail with a clear connection error
/// rather than silently hitting the wrong host.
final dioProvider = Provider<Dio>((Ref ref) {
  final Dio dio = Dio(_baseOptions());
  dio.interceptors.add(SigningInterceptor(ref.watch(_bareDioProvider)));
  return dio;
});

/// Typed wrapper other repositories call instead of touching Dio
/// directly (infrastructure/README: features never import
/// platform/plugin code directly).
final apiClientProvider = Provider<ApiClient>((Ref ref) {
  return ApiClient(ref.watch(dioProvider));
});

/// Live push channel (/ws/push). Not auto-connected here — call
/// `.connect()` once the user's identity is unlocked (e.g. after
/// login/signup completes).
final pushSocketProvider = Provider<PushSocket>((Ref ref) {
  return PushSocket(ref.watch(apiClientProvider));
});
