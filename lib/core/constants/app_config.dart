/// Runtime configuration.
///
/// Values are injected at build time via `--dart-define` so that no
/// endpoint is ever hardcoded in source:
///
/// flutter run --dart-define=API_BASE_URL=https://api.example.org \
///             --dart-define=WS_BASE_URL=wss://ws.example.org
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String wsBaseUrl = String.fromEnvironment('WS_BASE_URL');
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  static bool get isConfigured => apiBaseUrl.isNotEmpty;
}
