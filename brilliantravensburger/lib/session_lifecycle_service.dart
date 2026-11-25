import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Resultado al comprobar si Android cerró la app desde "aplicaciones activas".
class PendingTaskRemovalLogout {
  const PendingTaskRemovalLogout({
    required this.closedFromRecents,
    this.pendingToken,
  });

  final bool closedFromRecents;
  final String? pendingToken;
}

/// Coordina con el sistema nativo (Android `onTaskRemoved`) para detectar cuando
/// el usuario cierra la app y la quita de "aplicaciones activas".
class SessionLifecycleService {
  SessionLifecycleService._();

  static final SessionLifecycleService instance = SessionLifecycleService._();

  static const MethodChannel _channel = MethodChannel(
    'com.example.brilliantravensburger/session_lifecycle',
  );

  bool get _esAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> registrarSesionActiva({
    required String token,
    required String logoutUrl,
  }) async {
    if (!_esAndroid) return;
    try {
      await _channel.invokeMethod<void>('startSessionMonitor', {
        'token': token,
        'logoutUrl': logoutUrl,
      });
    } on MissingPluginException {
      // Ignorar en entornos de prueba o plataformas sin canal nativo.
    } catch (_) {}
  }

  Future<void> limpiarSesionActiva() async {
    if (!_esAndroid) return;
    try {
      await _channel.invokeMethod<void>('stopSessionMonitor');
    } on MissingPluginException {
      // Ignorar en entornos de prueba o plataformas sin canal nativo.
    } catch (_) {}
  }

  Future<PendingTaskRemovalLogout> consumirCierrePendiente() async {
    if (!_esAndroid) {
      return const PendingTaskRemovalLogout(closedFromRecents: false);
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'consumePendingLogout',
      );
      if (result == null) {
        return const PendingTaskRemovalLogout(closedFromRecents: false);
      }
      return PendingTaskRemovalLogout(
        closedFromRecents: result['closedFromRecents'] == true,
        pendingToken: result['pendingToken'] as String?,
      );
    } on MissingPluginException {
      return const PendingTaskRemovalLogout(closedFromRecents: false);
    } catch (_) {
      return const PendingTaskRemovalLogout(closedFromRecents: false);
    }
  }
}
