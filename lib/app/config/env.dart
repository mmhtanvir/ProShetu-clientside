import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class Env {
  static String get appName =>
      dotenv.env['APP_NAME'] ?? '';

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? '';

  static String get wsBaseUrl =>
      dotenv.env['WS_BASE_URL'] ?? '';

  static bool get enableLogger =>
      dotenv.env['ENABLE_LOGGER'] == 'true';

  static String get logLevel =>
      dotenv.env['LOG_LEVEL'] ?? 'none';
}