import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';
import 'app/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration
  const env = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  await dotenv.load(
    fileName: '.env.$env',
  );

  // Crisis app: no runtime font fetching.
  // Fonts must be bundled locally.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Configure device orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize dependency injection
  await configureDependencies();

  runApp(
    const ProviderScope(
      child: ProShetuApp(),
    ),
  );
}