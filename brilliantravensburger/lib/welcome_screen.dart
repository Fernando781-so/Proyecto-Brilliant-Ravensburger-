import 'dart:async';

import 'package:flutter/material.dart';

import 'audio_service.dart';
import 'auth_screen.dart';
import 'tablero_preview.dart';

/// Rutas de la imagen de fondo de la pantalla inicial.
class WelcomeBackgroundAssets {
  const WelcomeBackgroundAssets._();

  static const String imagenFondo = 'assets/images/fondo_inicio.jpeg';
}

/// Pantalla inicial ilustrativa antes de iniciar sesión.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AudioService.instance.detenerMusica());
    });
  }

  Future<void> _abrirAuth({required bool iniciarSesion}) async {
    unawaited(AudioService.instance.reproducirSelect());
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(initialLogin: iniciarSesion),
      ),
    );
    if (mounted) {
      unawaited(AudioService.instance.detenerMusica());
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final overlayColor = esOscuro
        ? Colors.black.withValues(alpha: 0.62)
        : Colors.white.withValues(alpha: 0.58);
    final tituloColor = esOscuro ? Colors.white : Colors.blue.shade900;
    final subtituloColor = esOscuro ? Colors.white : Colors.black87;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [AudioSettingsButton()],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            WelcomeBackgroundAssets.imagenFondo,
            key: const ValueKey('welcome-background-image'),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFondoIlustrativo(esOscuro),
          ),
          ColoredBox(color: overlayColor),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: esOscuro
                              ? Colors.grey.shade900.withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const TableroPreview(boardId: 1, size: 112),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'BRILLIANT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: tituloColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estrategia, dados y retos en tiempo real.\nPrepárate para conquistar el tablero.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: subtituloColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          key: const ValueKey('welcome-login-button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _abrirAuth(iniciarSesion: true),
                          icon: const Icon(Icons.login),
                          label: const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          key: const ValueKey('welcome-register-button'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: esOscuro
                                ? Colors.black.withValues(alpha: 0.55)
                                : Colors.white.withValues(alpha: 0.88),
                            foregroundColor: esOscuro
                                ? Colors.white
                                : Colors.blue.shade900,
                            side: BorderSide(
                              color: esOscuro
                                  ? Colors.white70
                                  : Colors.blue.shade700,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _abrirAuth(iniciarSesion: false),
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text(
                            'Crear Cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFondoIlustrativo(bool esOscuro) {
    return Container(
      key: const ValueKey('welcome-default-background'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: esOscuro
              ? [
                  Colors.black,
                  Colors.blueGrey.shade900,
                  Colors.indigo.shade900,
                ]
              : [
                  Colors.blue.shade100,
                  Colors.amber.shade100,
                  Colors.purple.shade100,
                ],
        ),
      ),
    );
  }
}
