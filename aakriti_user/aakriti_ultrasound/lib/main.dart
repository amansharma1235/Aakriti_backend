import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:aakriti_ultrasound/screen/splash_screen.dart';
import 'package:aakriti_ultrasound/services/theme_controller.dart';
import 'package:aakriti_ultrasound/services/notification_service.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase initialize safely
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Initialize theme mode from preferences
  await ThemeController.instance.init();

  runApp(const AakritiUltrasoundApp());

  // 🔔 Firebase Push Notification initialize safely after UI is ready
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }
}

class AakritiUltrasoundApp extends StatelessWidget {
  const AakritiUltrasoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          title: 'Aakriti Ultrasound',

          themeMode: themeMode,

          // ☀️ Light Theme
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Arial',
            brightness: Brightness.light,
            cardColor: Colors.white,
            scaffoldBackgroundColor: const Color(0xFFF5F8FC),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1677FF),
              brightness: Brightness.light,
              surface: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF071A2B),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),

          // 🌙 Dark Theme
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Arial',
            brightness: Brightness.dark,
            cardColor: const Color(0xFF0C1F33),
            scaffoldBackgroundColor: const Color(0xFF06121F),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF0C1F33),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1677FF),
              brightness: Brightness.dark,
              surface: const Color(0xFF0C1F33),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF071A2B),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}
