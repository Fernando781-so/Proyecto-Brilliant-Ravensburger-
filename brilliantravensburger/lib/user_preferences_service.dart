import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'audio_service.dart';
import 'theme_service.dart';

/// Persiste en disco las preferencias de tema, música, sonidos y volúmenes.
class UserPreferencesService {
  UserPreferencesService._();

  static final UserPreferencesService instance = UserPreferencesService._();

  static const String _storageKey = 'brilliant_user_preferences_v1';
  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage();

  Future<String?> Function(String key)? _customReader;
  Future<void> Function(String key, String value)? _customWriter;
  bool _cargando = false;

  bool get _esEntornoDePruebas {
    if (_customReader != null || _customWriter != null) return false;
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return bindingName.contains('TestWidgetsFlutterBinding') ||
        bindingName.contains('AutomatedTestWidgetsFlutterBinding') ||
        bindingName.contains('LiveTestWidgetsFlutterBinding');
  }

  @visibleForTesting
  void configurarAlmacenamientoParaPruebas({
    Future<String?> Function(String key)? reader,
    Future<void> Function(String key, String value)? writer,
  }) {
    _customReader = reader;
    _customWriter = writer;
  }

  @visibleForTesting
  void limpiarAlmacenamientoParaPruebas() {
    _customReader = null;
    _customWriter = null;
  }

  Future<void> cargarPreferencias() async {
    if (_esEntornoDePruebas) return;
    _cargando = true;
    try {
      final raw = _customReader != null
          ? await _customReader!(_storageKey)
          : await _defaultStorage.read(key: _storageKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      if (decoded['fondoOscuro'] is bool) {
        ThemeService.instance.establecerFondoOscuro(
          decoded['fondoOscuro'] as bool,
          guardar: false,
        );
      }
      final audio = AudioService.instance;
      if (decoded['volumenMusica'] is num) {
        audio.ajustarVolumenMusica(
          (decoded['volumenMusica'] as num).toDouble(),
          guardar: false,
        );
      }
      if (decoded['volumenSonidos'] is num) {
        audio.ajustarVolumenSonidos(
          (decoded['volumenSonidos'] as num).toDouble(),
          guardar: false,
        );
      }
      if (decoded['musicaActiva'] is bool) {
        audio.alternarMusica(decoded['musicaActiva'] as bool, false);
      }
      if (decoded['sonidosActivos'] is bool) {
        audio.alternarSonidos(decoded['sonidosActivos'] as bool, false);
      }
    } on MissingPluginException {
      // Ignorar en entornos sin soporte de plugin.
    } catch (_) {
      // Ignorar datos corruptos para no bloquear el inicio de la app.
    } finally {
      _cargando = false;
    }
  }

  Future<void> guardarPreferencias() async {
    if (_cargando || _esEntornoDePruebas) return;
    final payload = jsonEncode({
      'fondoOscuro': ThemeService.instance.esFondoOscuro,
      'musicaActiva': AudioService.instance.musicaActiva,
      'sonidosActivos': AudioService.instance.sonidosActivos,
      'volumenMusica': AudioService.instance.volumenMusica,
      'volumenSonidos': AudioService.instance.volumenSonidos,
    });
    try {
      if (_customWriter != null) {
        await _customWriter!(_storageKey, payload);
      } else {
        await _defaultStorage.write(key: _storageKey, value: payload);
      }
    } on MissingPluginException {
      // Ignorar en entornos sin soporte de plugin.
    } catch (_) {}
  }
}
