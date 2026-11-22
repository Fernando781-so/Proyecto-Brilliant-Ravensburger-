import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Rutas centralizadas de los archivos de música y efectos de sonido.
///
/// Coloca tus archivos en:
/// - `assets/audio/musica/`
/// - `assets/audio/sonidos/`
class AudioAssets {
  const AudioAssets._();

  static const String carpetaMusica = 'assets/audio/musica';
  static const String carpetaSonidos = 'assets/audio/sonidos';

  // Música de fondo
  static const String musicaMenu = '$carpetaMusica/menu.mp3';
  static const String musicaPartida = '$carpetaMusica/partida.mp3';

  // Efectos de sonido (SFX)
  static const String sonidoBoton = '$carpetaSonidos/boton.mp3';
  static const String sonidoDado = '$carpetaSonidos/dado.mp3';
  static const String sonidoColocarNumero =
      '$carpetaSonidos/colocar_numero.mp3';
  static const String sonidoExplosion = '$carpetaSonidos/explosion.mp3';
  static const String sonidoZonaCapturada =
      '$carpetaSonidos/zona_capturada.mp3';
  static const String sonidoVictoria = '$carpetaSonidos/victoria.mp3';
}

/// Servicio centralizado para controlar el estado de música y sonidos.
class AudioService extends ChangeNotifier {
  AudioService._();

  static final AudioService instance = AudioService._();

  bool _musicaActiva = true;
  bool _sonidosActivos = true;
  double _volumenMusica = 0.7;
  double _volumenSonidos = 1.0;
  String? _pistaMusicaActual;

  bool get musicaActiva => _musicaActiva;
  bool get sonidosActivos => _sonidosActivos;
  double get volumenMusica => _volumenMusica;
  double get volumenSonidos => _volumenSonidos;
  String? get pistaMusicaActual => _pistaMusicaActual;

  void alternarMusica([bool? activa]) {
    final nuevoValor = activa ?? !_musicaActiva;
    if (_musicaActiva == nuevoValor) return;
    _musicaActiva = nuevoValor;
    if (!_musicaActiva) {
      _pistaMusicaActual = null;
    }
    notifyListeners();
  }

  void alternarSonidos([bool? activos]) {
    final nuevoValor = activos ?? !_sonidosActivos;
    if (_sonidosActivos == nuevoValor) return;
    _sonidosActivos = nuevoValor;
    notifyListeners();
  }

  void ajustarVolumenMusica(double volumen) {
    _volumenMusica = volumen.clamp(0.0, 1.0);
    notifyListeners();
  }

  void ajustarVolumenSonidos(double volumen) {
    _volumenSonidos = volumen.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Verifica si el archivo de audio ya fue agregado a la carpeta `assets/audio/`.
  Future<bool> existeArchivoAudio(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Prepara o cambia la pista de música de fondo si la música está activa.
  Future<void> reproducirMusica(String assetPath) async {
    if (!_musicaActiva) return;
    _pistaMusicaActual = assetPath;
    notifyListeners();
  }

  /// Detiene la pista de música actual.
  Future<void> detenerMusica() async {
    if (_pistaMusicaActual == null) return;
    _pistaMusicaActual = null;
    notifyListeners();
  }

  /// Reproduce un efecto de sonido corto si los sonidos están activos.
  Future<void> reproducirSonido(String assetPath) async {
    if (!_sonidosActivos) return;
    await SystemSound.play(SystemSoundType.click);
  }
}
