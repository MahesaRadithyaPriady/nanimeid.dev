import 'dart:async';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'controllers/settings_controller.dart';
import 'screen/protected/anime_list_screen.dart';

import 'screen/splash_screen.dart';
import 'screen/protected/home_screen.dart';
import 'screen/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture framework errors with full stack traces in all modes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Catch uncaught asynchronous errors
  WidgetsBinding.instance.platformDispatcher.onError = (Object error, StackTrace stack) {
    // Prefer debugPrint to avoid truncation
    debugPrint('Uncaught platformDispatcher error: ' + error.toString());
    debugPrint(stack.toString());
    return true; // mark as handled to avoid default crash spam
  };

  // Initialize and run the app inside a guarded zone
  runZonedGuarded(() async {
    // Initialize global HTTP client (Dio) with auth token interceptor
    ApiService.initialize();

    runApp(const MyApp());
  }, (Object error, StackTrace stack) {
    debugPrint('Uncaught zone error: ' + error.toString());
    debugPrint(stack.toString());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nanimeid',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      navigatorObservers: [SettingsRouteObserver()],
      routes: {
        '/home': (context) => const HomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        // Temporary route for generic anime list browse
        '/anime': (context) => const AnimeListScreen(),
      },
    );
  }
}
