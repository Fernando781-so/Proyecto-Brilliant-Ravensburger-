import 'dart:async';

import 'package:flutter/material.dart';
import 'theme_service.dart';
import 'user_preferences_service.dart';
import 'welcome_screen.dart';

void main() {
  runApp(const BrilliantApp());
}

class BrilliantApp extends StatefulWidget {
  const BrilliantApp({super.key});

  @override
  State<BrilliantApp> createState() => _BrilliantAppState();
}

class _BrilliantAppState extends State<BrilliantApp> {
  @override
  void initState() {
    super.initState();
    unawaited(UserPreferencesService.instance.cargarPreferencias());
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Brilliant Ravensburger',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.94),
                foregroundColor: Colors.blue.shade900,
                side: BorderSide(color: Colors.blue.shade700, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.90),
                foregroundColor: Colors.blue.shade900,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.94),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: Colors.black,
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF1F242D).withValues(alpha: 0.94),
                foregroundColor: Colors.lightBlue.shade100,
                side: BorderSide(color: Colors.lightBlue.shade300, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1F242D).withValues(alpha: 0.90),
                foregroundColor: Colors.lightBlue.shade100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1F242D).withValues(alpha: 0.94),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          home: const WelcomeScreen(),
        );
      },
    );
  }
}
