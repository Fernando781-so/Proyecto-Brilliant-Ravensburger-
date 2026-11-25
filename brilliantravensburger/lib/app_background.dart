import 'package:flutter/material.dart';

/// Fondo global con `assets/images/fondo.jpeg` usado en todas las pantallas
/// excepto la pantalla inicial (`WelcomeScreen`).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  static const String imagenFondo = 'assets/images/fondo.jpeg';

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final overlayColor = esOscuro
        ? Colors.black.withValues(alpha: 0.62)
        : Colors.white.withValues(alpha: 0.45);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagenFondo,
          key: const ValueKey('app-background-image'),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: esOscuro ? Colors.black : Colors.white,
          ),
        ),
        ColoredBox(color: overlayColor),
        child,
      ],
    );
  }
}
