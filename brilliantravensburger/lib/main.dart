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
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: Colors.black,
          ),
          home: const WelcomeScreen(),
        );
      },
    );
  }
}
