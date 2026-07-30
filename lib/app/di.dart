import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_config.dart';

/// Composition root.
///
/// Riverpod providers *are* the DI container: everything below is
/// lazily created on first read and disposable in tests via overrides.

/// Secure at-rest key/value storage (Android Keystore / iOS Keychain).
final secureStorageProvider = Provider<FlutterSecureStorage>((Ref ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

/// Configured HTTP client. Base URL comes exclusively from
/// [AppConfig] — never hardcode endpoints.
final dioProvider = Provider<Dio>((Ref ref) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );
  // Interceptors (auth, retry, logging) are attached when the
  // session layer lands.
  return dio;
});
