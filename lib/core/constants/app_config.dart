/// Runtime configuration.
///
/// Values are injected at build time via `--dart-define` so that no
/// endpoint or secret is ever hardcoded in source:
///
/// flutter run --dart-define=API_BASE_URL=https://api.example.org \
///             --dart-define=WS_BASE_URL=wss://ws.example.org \
///             --dart-define=GOOGLE_FLOOD_API_KEY=your-key
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String wsBaseUrl = String.fromEnvironment('WS_BASE_URL');
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  /// Key for Google's Flood Forecasting API
  /// (floodforecasting.googleapis.com) — a separate, pilot-access-gated
  /// API, distinct from the Maps SDK key in android/local.properties
  /// and ios Info.plist's GMSApiKey.
  static const String googleFloodApiKey =
      String.fromEnvironment('GOOGLE_FLOOD_API_KEY');

  static bool get isConfigured => apiBaseUrl.isNotEmpty;
  static bool get isFloodApiConfigured => googleFloodApiKey.isNotEmpty;
}
