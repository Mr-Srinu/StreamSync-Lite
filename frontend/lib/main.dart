// lib/main.dart
import 'package:flutter/material.dart';
import 'models/user.dart';
import 'services/session_manager.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme_controller.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  runApp(const StreamSyncApp());
}

class StreamSyncApp extends StatelessWidget {
  const StreamSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'StreamSync Lite',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.mode,
          theme: ThemeData(
            colorSchemeSeed: Colors.redAccent,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.redAccent,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF050505),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
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
