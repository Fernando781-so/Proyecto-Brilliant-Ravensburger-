import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme_service.dart';
import 'user_preferences_service.dart';

/// Rutas centralizadas de los archivos de música y efectos de sonido.
class AudioAssets {
  const AudioAssets._();

  static const String carpetaMusica = 'assets/audio/musica';
  static const String carpetaSonidos = 'assets/audio/sonidos';

  // Música de fondo
  static const String musicaMenu = '$carpetaMusica/Trophy Gallery.mp3';
  static const String musicaPartidaCasual = '$carpetaMusica/The Classroom.mp3';
  static const String musicaPartidaClasificatoria =
      '$carpetaMusica/Final Destination.mp3';

  // Efectos de sonido (SFX)
  static const String sonidoBack = '$carpetaSonidos/back-button.mp3';
  static const String sonidoSelect = '$carpetaSonidos/select.mp3';
  static const String sonidoDado = '$carpetaSonidos/Dado.wav';
  static const String sonidoColocarNumero = '$carpetaSonidos/C_numero.mp3';
  static const String sonidoDeshacerNumero = '$carpetaSonidos/D_numero.mp3';
  static const String sonidoExplosion =
      '$carpetaSonidos/deltarune_explosion.wav';
  static const String sonidoZonaPropia = '$carpetaSonidos/Zona.wav';
  static const String sonidoZonaOtroJugador =
      '$carpetaSonidos/Gato_riendose_Meme.wav';
  static const String sonidoFinPartida = '$carpetaSonidos/End_game.mp3';
}

/// Servicio centralizado para controlar la música en ciclo continuo y los efectos de sonido.
class AudioService extends ChangeNotifier {
  AudioService._();

  static final AudioService instance = AudioService._();

  AudioPlayer? _musicPlayer;
  bool _musicaActiva = true;
  bool _sonidosActivos = true;
  double _volumenMusica = 0.7;
  double _volumenSonidos = 1.0;
  String? _pistaMusicaActual;
  String? _pistaMusicaObjetivo;
  String? _ultimoSonidoReproducido;
  final List<String> _historialSonidos = <String>[];
  int _conteoIniciosMusica = 0;
  bool _musicaReproduciendoEnReproductor = false;

  bool get musicaActiva => _musicaActiva;
  bool get sonidosActivos => _sonidosActivos;
  double get volumenMusica => _volumenMusica;
  double get volumenSonidos => _volumenSonidos;
  String? get pistaMusicaActual => _pistaMusicaActual;
  String? get pistaMusicaObjetivo => _pistaMusicaObjetivo;
  String? get ultimoSonidoReproducido => _ultimoSonidoReproducido;
  List<String> get historialSonidos => List.unmodifiable(_historialSonidos);
  int get conteoIniciosMusica => _conteoIniciosMusica;

  bool get _esEntornoDePruebas {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return bindingName.contains('TestWidgetsFlutterBinding') ||
        bindingName.contains('AutomatedTestWidgetsFlutterBinding') ||
        bindingName.contains('LiveTestWidgetsFlutterBinding');
  }

  static String _rutaRelativaParaAssetSource(String assetPath) {
    if (assetPath.startsWith('assets/')) {
      return assetPath.substring('assets/'.length);
    }
    return assetPath;
  }

  static String? _rutaAlternativaExtension(String assetPath) {
    if (assetPath.endsWith('.wav')) {
      return '${assetPath.substring(0, assetPath.length - 4)}.mp3';
    }
    if (assetPath.endsWith('.mp3')) {
      return '${assetPath.substring(0, assetPath.length - 4)}.wav';
    }
    return null;
  }

  @visibleForTesting
  void reiniciarEstadoParaPruebas() {
    _musicaActiva = true;
    _sonidosActivos = true;
    _volumenMusica = 0.7;
    _volumenSonidos = 1.0;
    _pistaMusicaActual = null;
    _pistaMusicaObjetivo = null;
    _ultimoSonidoReproducido = null;
    _historialSonidos.clear();
    _conteoIniciosMusica = 0;
    _musicaReproduciendoEnReproductor = false;
  }

  void alternarMusica([bool? activa, bool guardar = true]) {
    final nuevoValor = activa ?? !_musicaActiva;
    if (_musicaActiva == nuevoValor) return;
    _musicaActiva = nuevoValor;
    if (!_musicaActiva) {
      _pistaMusicaActual = null;
      _musicaReproduciendoEnReproductor = false;
      if (!_esEntornoDePruebas) {
        unawaited(_detenerReproductorMusica());
      }
      notifyListeners();
    } else {
      notifyListeners();
      if (_pistaMusicaObjetivo != null) {
        unawaited(
          reproducirMusica(_pistaMusicaObjetivo!, forzarReinicio: true),
        );
      }
    }
    if (guardar) {
      unawaited(UserPreferencesService.instance.guardarPreferencias());
    }
  }

  void alternarSonidos([bool? activos, bool guardar = true]) {
    final nuevoValor = activos ?? !_sonidosActivos;
    if (_sonidosActivos == nuevoValor) return;
    _sonidosActivos = nuevoValor;
    notifyListeners();
    if (guardar) {
      unawaited(UserPreferencesService.instance.guardarPreferencias());
    }
  }

  void ajustarVolumenMusica(double volumen, {bool guardar = true}) {
    _volumenMusica = volumen.clamp(0.0, 1.0);
    if (!_esEntornoDePruebas) {
      try {
        unawaited(_musicPlayer?.setVolume(_volumenMusica));
      } catch (_) {}
    }
    notifyListeners();
    if (guardar) {
      unawaited(UserPreferencesService.instance.guardarPreferencias());
    }
  }

  void ajustarVolumenSonidos(double volumen, {bool guardar = true}) {
    _volumenSonidos = volumen.clamp(0.0, 1.0);
    notifyListeners();
    if (guardar) {
      unawaited(UserPreferencesService.instance.guardarPreferencias());
    }
  }

  /// Verifica si el archivo de audio existe en `assets/audio/`.
  Future<bool> existeArchivoAudio(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      final alternativa = _rutaAlternativaExtension(assetPath);
      if (alternativa != null) {
        try {
          await rootBundle.load(alternativa);
          return true;
        } catch (_) {}
      }
      return false;
    }
  }

  /// Reproduce música de fondo en bucle continuo (`ReleaseMode.loop`).
  /// Si la misma pista ya está sonando, NO la reinicia para mantener el ciclo entre turnos.
  Future<void> reproducirMusica(
    String assetPath, {
    bool forzarReinicio = false,
  }) async {
    _pistaMusicaObjetivo = assetPath;
    if (!_musicaActiva) {
      _pistaMusicaActual = null;
      _musicaReproduciendoEnReproductor = false;
      return;
    }

    if (_pistaMusicaActual == assetPath &&
        !forzarReinicio &&
        (_esEntornoDePruebas || _musicaReproduciendoEnReproductor)) {
      return;
    }

    final yaEstabaComoActual = _pistaMusicaActual == assetPath;
    _pistaMusicaActual = assetPath;
    if (!yaEstabaComoActual || forzarReinicio) {
      _conteoIniciosMusica++;
    }
    notifyListeners();

    if (_esEntornoDePruebas) return;

    try {
      final player = _musicPlayer ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_volumenMusica);
      if (player.state == PlayerState.playing ||
          player.state == PlayerState.paused) {
        await player.stop();
      }
      await player.play(
        AssetSource(_rutaRelativaParaAssetSource(assetPath)),
        volume: _volumenMusica,
      );
      _musicaReproduciendoEnReproductor = true;
    } catch (_) {
      _musicaReproduciendoEnReproductor = false;
      final alternativa = _rutaAlternativaExtension(assetPath);
      if (alternativa != null) {
        try {
          final player = _musicPlayer ??= AudioPlayer();
          await player.setReleaseMode(ReleaseMode.loop);
          await player.play(
            AssetSource(_rutaRelativaParaAssetSource(alternativa)),
            volume: _volumenMusica,
          );
          _musicaReproduciendoEnReproductor = true;
        } catch (_) {
          _musicaReproduciendoEnReproductor = false;
        }
      }
    }
  }

  Future<void> _detenerReproductorMusica() async {
    _musicaReproduciendoEnReproductor = false;
    try {
      await _musicPlayer?.stop();
    } catch (_) {}
  }

  /// Detiene la pista de música actual.
  Future<void> detenerMusica() async {
    if (_pistaMusicaActual == null && _pistaMusicaObjetivo == null) return;
    _pistaMusicaActual = null;
    _pistaMusicaObjetivo = null;
    _musicaReproduciendoEnReproductor = false;
    if (!_esEntornoDePruebas) {
      await _detenerReproductorMusica();
    }
    notifyListeners();
  }

  /// Reproduce un efecto de sonido corto si los sonidos están activos.
  Future<void> reproducirSonido(String assetPath) async {
    if (!_esEntornoDePruebas &&
        _musicaActiva &&
        _pistaMusicaObjetivo != null &&
        !_musicaReproduciendoEnReproductor) {
      unawaited(reproducirMusica(_pistaMusicaObjetivo!));
    }
    if (!_sonidosActivos) return;
    _ultimoSonidoReproducido = assetPath;
    _historialSonidos.add(assetPath);
    notifyListeners();

    if (_esEntornoDePruebas) return;

    try {
      final sfxPlayer = AudioPlayer();
      await sfxPlayer.setReleaseMode(ReleaseMode.release);
      await sfxPlayer.setVolume(_volumenSonidos);
      sfxPlayer.onPlayerComplete.first.then((_) {
        sfxPlayer.dispose();
      }).catchError((_) {});
      try {
        await sfxPlayer.play(
          AssetSource(_rutaRelativaParaAssetSource(assetPath)),
          volume: _volumenSonidos,
        );
      } catch (_) {
        final alternativa = _rutaAlternativaExtension(assetPath);
        if (alternativa != null) {
          await sfxPlayer.play(
            AssetSource(_rutaRelativaParaAssetSource(alternativa)),
            volume: _volumenSonidos,
          );
        } else {
          await sfxPlayer.dispose();
        }
      }
    } catch (_) {}
  }

  Future<void> reproducirMusicaMenu() =>
      reproducirMusica(AudioAssets.musicaMenu);

  Future<void> reproducirMusicaPartida({required bool clasificatoria}) =>
      reproducirMusica(
        clasificatoria
            ? AudioAssets.musicaPartidaClasificatoria
            : AudioAssets.musicaPartidaCasual,
      );

  Future<void> reproducirSelect() => reproducirSonido(AudioAssets.sonidoSelect);

  Future<void> reproducirBack() => reproducirSonido(AudioAssets.sonidoBack);

  Future<void> reproducirDado() => reproducirSonido(AudioAssets.sonidoDado);

  Future<void> reproducirColocarNumero() =>
      reproducirSonido(AudioAssets.sonidoColocarNumero);

  Future<void> reproducirDeshacerNumero() =>
      reproducirSonido(AudioAssets.sonidoDeshacerNumero);

  Future<void> reproducirExplosion() =>
      reproducirSonido(AudioAssets.sonidoExplosion);

  Future<void> reproducirZonaPropia() =>
      reproducirSonido(AudioAssets.sonidoZonaPropia);

  Future<void> reproducirZonaOtroJugador() =>
      reproducirSonido(AudioAssets.sonidoZonaOtroJugador);

  Future<void> reproducirFinPartida() =>
      reproducirSonido(AudioAssets.sonidoFinPartida);
}

/// Botón de engranaje siempre visible en las barras superiores para activar/desactivar
/// por separado la música y los efectos de sonido.
class AudioSettingsButton extends StatelessWidget {
  const AudioSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('audio-settings-button'),
      tooltip: 'Configuración de audio',
      icon: const Icon(Icons.settings),
      onPressed: () {
        unawaited(AudioService.instance.reproducirSelect());
        mostrarDialogoConfiguracionAudio(context);
      },
    );
  }
}

Future<void> mostrarDialogoConfiguracionAudio(BuildContext context) {
  final audio = AudioService.instance;
  final theme = ThemeService.instance;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return ListenableBuilder(
        listenable: Listenable.merge([audio, theme]),
        builder: (context, _) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.settings, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(child: Text('Configuración de audio')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  key: const ValueKey('toggle-musica-switch'),
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    audio.musicaActiva ? Icons.music_note : Icons.music_off,
                    color: audio.musicaActiva ? Colors.blue : Colors.grey,
                  ),
                  title: const Text(
                    'Música',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    audio.musicaActiva ? 'Activada' : 'Desactivada',
                  ),
                  value: audio.musicaActiva,
                  onChanged: (value) {
                    audio.alternarMusica(value);
                    unawaited(audio.reproducirSelect());
                  },
                ),
                const Divider(),
                SwitchListTile(
                  key: const ValueKey('toggle-sonidos-switch'),
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    audio.sonidosActivos ? Icons.volume_up : Icons.volume_off,
                    color: audio.sonidosActivos ? Colors.green : Colors.grey,
                  ),
                  title: const Text(
                    'Sonidos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    audio.sonidosActivos ? 'Activados' : 'Desactivados',
                  ),
                  value: audio.sonidosActivos,
                  onChanged: (value) {
                    audio.alternarSonidos(value);
                    if (value) {
                      unawaited(audio.reproducirSelect());
                    }
                  },
                ),
                const Divider(),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Color del fondo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('fondo-blanco-button'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: !theme.esFondoOscuro
                              ? Colors.blue.shade50
                              : null,
                          foregroundColor: !theme.esFondoOscuro
                              ? Colors.blue.shade900
                              : null,
                          side: BorderSide(
                            color: !theme.esFondoOscuro
                                ? Colors.blue
                                : Colors.grey,
                            width: !theme.esFondoOscuro ? 2 : 1,
                          ),
                        ),
                        onPressed: () {
                          unawaited(audio.reproducirSelect());
                          theme.establecerFondoOscuro(false);
                        },
                        icon: const Icon(Icons.light_mode, size: 18),
                        label: const Text('Blanco'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('fondo-negro-button'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: theme.esFondoOscuro
                              ? Colors.grey.shade800
                              : null,
                          foregroundColor: theme.esFondoOscuro
                              ? Colors.white
                              : null,
                          side: BorderSide(
                            color: theme.esFondoOscuro
                                ? Colors.amber
                                : Colors.grey,
                            width: theme.esFondoOscuro ? 2 : 1,
                          ),
                        ),
                        onPressed: () {
                          unawaited(audio.reproducirSelect());
                          theme.establecerFondoOscuro(true);
                        },
                        icon: const Icon(Icons.dark_mode, size: 18),
                        label: const Text('Negro'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                key: const ValueKey('close-audio-settings-button'),
                onPressed: () {
                  unawaited(audio.reproducirBack());
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    },
  );
}
