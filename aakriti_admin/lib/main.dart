import 'package:flutter/material.dart';

import 'controllers/profile_controller.dart';
import 'screens/login/login_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ThemeController.instance.init();
  await ProfileController.instance.init();
  runApp(const AakritiAdminApp());
}

class AakritiAdminApp extends StatelessWidget {
  const AakritiAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Aakriti Ultrasound Admin',
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const LoginScreen(),
        );
      },
    );
  }
}
