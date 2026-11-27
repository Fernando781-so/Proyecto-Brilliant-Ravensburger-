import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'app_background.dart';
import 'app_config.dart';
import 'audio_service.dart';
import 'inicio_screen.dart';
import 'lobby_screen.dart';
import 'modos_juego_info.dart';
import 'multiplayer_service.dart';
import 'session_lifecycle_service.dart';

class PlayerProfile {
  const PlayerProfile({
    required this.rankedPoints,
    required this.rankedLevel,
    required this.gamesPlayed,
    required this.wins,
    required this.currentStreak,
  });

  final int rankedPoints;
  final String rankedLevel;
  final int gamesPlayed;
  final int wins;
  final int currentStreak;

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final pts = (json['rankedPoints'] as num?)?.toInt() ?? eloInicial;
    final safePts = pts < eloMinimo ? eloInicial : pts;
    return PlayerProfile(
      rankedPoints: safePts,
      rankedLevel:
          (json['rankedLevel'] as String?) ?? obtenerNivelRanked(safePts),
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialLogin = true});

  final bool initialLogin;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const FlutterSecureStorage _sessionStorage = FlutterSecureStorage();
  static const String _savedSessionKey = 'auth_session';

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late bool _isLogin;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _token;
  String? _currentUser;
  PlayerProfile? _profile;
  AppLifecycleListener? _lifecycleListener;
  bool _closingSessionOnExit = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialLogin;
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: _handleAppExitRequested,
      onDetach: () {
        unawaited(_cerrarSesionAlCerrarApp());
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_token == null) {
        unawaited(AudioService.instance.detenerMusica());
      }
    });
    _restoreSession();
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<AppExitResponse> _handleAppExitRequested() async {
    await _cerrarSesionAlCerrarApp();
    return AppExitResponse.exit;
  }

  Future<void> _cerrarSesionAlCerrarApp() async {
    final activeToken = _token;
    if (activeToken == null || _closingSessionOnExit) return;
    _closingSessionOnExit = true;
    unawaited(AudioService.instance.detenerMusica());
    unawaited(SessionLifecycleService.instance.limpiarSesionActiva());
    try {
      await http
          .post(
            Uri.parse('$baseUrl/logout'),
            headers: {'Authorization': 'Bearer $activeToken'},
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // No bloquear el cierre de la ventana si el servidor no responde a tiempo.
    }
    try {
      await _sessionStorage.delete(key: _savedSessionKey);
    } catch (_) {}
  }

  void _activarSesionLocal({required String token, required String username}) {
    setState(() {
      _token = token;
      _currentUser = username;
      _closingSessionOnExit = false;
    });
    unawaited(
      SessionLifecycleService.instance.registrarSesionActiva(
        token: token,
        logoutUrl: '$baseUrl/logout',
      ),
    );
    unawaited(AudioService.instance.reproducirMusicaMenu());
    unawaited(_cargarPerfilJugador(token));
  }

  Future<void> _cargarPerfilJugador(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/profile'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 6));
      if (!mounted || _token != token) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          setState(() {
            _profile = PlayerProfile.fromJson(decoded);
          });
        }
      }
    } catch (_) {
      // Si el servidor no responde, mantener el perfil por defecto o previo.
    }
  }

  Future<void> _restoreSession() async {
    try {
      final pendingLogout = await SessionLifecycleService.instance
          .consumirCierrePendiente();
      if (pendingLogout.closedFromRecents) {
        if (pendingLogout.pendingToken != null &&
            pendingLogout.pendingToken!.isNotEmpty) {
          try {
            await http
                .post(
                  Uri.parse('$baseUrl/logout'),
                  headers: {
                    'Authorization': 'Bearer ${pendingLogout.pendingToken}',
                  },
                )
                .timeout(const Duration(seconds: 4));
          } catch (_) {}
        }
        try {
          await _sessionStorage.delete(key: _savedSessionKey);
        } catch (_) {}
        unawaited(AudioService.instance.detenerMusica());
        return;
      }

      final savedSession = await _sessionStorage.read(key: _savedSessionKey);
      if (savedSession == null) return;

      final decodedSession = jsonDecode(savedSession);
      if (decodedSession is! Map ||
          decodedSession['token'] is! String ||
          decodedSession['username'] is! String) {
        await _sessionStorage.delete(key: _savedSessionKey);
        if (mounted) _mostrarError('La sesión guardada no es válida.');
        return;
      }

      final savedToken = decodedSession['token'] as String;
      var savedUsername = decodedSession['username'] as String;
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/session'),
          headers: {'Authorization': 'Bearer $savedToken'},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          savedUsername = data['username'] ?? savedUsername;
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          await _sessionStorage.delete(key: _savedSessionKey);
          unawaited(SessionLifecycleService.instance.limpiarSesionActiva());
          unawaited(AudioService.instance.detenerMusica());
          if (mounted) {
            _mostrarError('La sesión ya no está activa. Inicia sesión.');
          }
          return;
        } else if (mounted) {
          _mostrarError('No se pudo validar la sesión con el servidor.');
        }
      } catch (error) {
        if (mounted) {
          _mostrarError('No se pudo validar la sesión con el servidor.');
        }
      }

      if (mounted) {
        _activarSesionLocal(token: savedToken, username: savedUsername);
      }
    } catch (error) {
      if (mounted) _mostrarError('No se pudo restaurar la sesión guardada.');
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final endpoint = _isLogin ? '/login' : '/register';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      // 👈 AQUÍ VA LA LÍNEA: evita usar 'context' si la pantalla se cerró durante la petición
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (_isLogin) {
          final token = data['token'] as String?;
          if (token == null) {
            _mostrarError('El servidor no devolvió un token de sesión.');
            return;
          }
          final username = _usernameController.text.trim();
          try {
            await _sessionStorage.write(
              key: _savedSessionKey,
              value: jsonEncode({'token': token, 'username': username}),
            );
          } catch (error) {
            if (!mounted) return;
            _activarSesionLocal(token: token, username: username);
            _mostrarError(
              'No se pudo guardar la sesión en este dispositivo. '
              'Cierra sesión antes de salir.',
            );
            return;
          }
          if (!mounted) return;
          _activarSesionLocal(token: token, username: username);
        } else {
          setState(() => _isLogin = true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'],
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (_isLogin &&
          response.statusCode == 409 &&
          data is Map &&
          data['code'] == 'SESSION_ACTIVE') {
        await _confirmarRecuperacionSesion();
      } else if (!_isLogin &&
          (response.statusCode == 409 ||
              (response.statusCode == 400 &&
                  data is Map &&
                  data['error'] == 'El usuario ya existe'))) {
        setState(() => _isLogin = true);
        _mostrarError(
          'Ese nombre de usuario ya está registrado. Inicia sesión.',
        );
      } else {
        _mostrarError(data['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      _mostrarError('Error de conexión con el servidor');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmarRecuperacionSesion() async {
    final recuperar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('La cuenta ya tiene una sesión activa'),
        content: const Text(
          'Puedes cerrar la sesión anterior e iniciar aquí. El otro dispositivo tendrá que volver a iniciar sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar sesión anterior'),
          ),
        ],
      ),
    );
    if (recuperar != true || !mounted) return;

    final username = _usernameController.text.trim();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/recover'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': _passwordController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode != 200) {
        _mostrarError(
          data is Map
              ? data['error'] ?? 'No se pudo recuperar la sesión.'
              : 'No se pudo recuperar la sesión.',
        );
        return;
      }

      final token = data['token'] as String?;
      if (token == null) {
        _mostrarError('El servidor no devolvió un token de sesión.');
        return;
      }

      try {
        await _sessionStorage.write(
          key: _savedSessionKey,
          value: jsonEncode({'token': token, 'username': username}),
        );
      } catch (error) {
        if (!mounted) return;
        _activarSesionLocal(token: token, username: username);
        _mostrarError(
          'Sesión recuperada, pero no se pudo guardar en este dispositivo.',
        );
        return;
      }

      if (!mounted) return;
      _activarSesionLocal(token: token, username: username);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión anterior cerrada. Ya puedes continuar.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (mounted) {
        _mostrarError('No se pudo recuperar la sesión. Intenta nuevamente.');
      }
    }
  }

  Future<void> _logout() async {
    if (_token == null) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        final wasAlreadyClosed = response.statusCode != 200;
        setState(() {
          _token = null;
          _currentUser = null;
          _profile = null;
          _usernameController.clear();
          _passwordController.clear();
          _isPasswordVisible = false;
        });
        unawaited(AudioService.instance.detenerMusica());
        unawaited(SessionLifecycleService.instance.limpiarSesionActiva());
        try {
          await _sessionStorage.delete(key: _savedSessionKey);
        } catch (error) {
          if (mounted) {
            _mostrarError(
              'Se cerró la sesión, pero no se pudo borrar del dispositivo.',
            );
          }
        }
        if (wasAlreadyClosed && mounted) {
          _mostrarError(
            'La sesión anterior ya no estaba activa. Inicia sesión nuevamente.',
          );
        }
      } else {
        final data = jsonDecode(response.body);
        _mostrarError(data['error'] ?? 'No se pudo cerrar la sesión.');
      }
    } catch (error) {
      _mostrarError(
        'No se pudo cerrar la sesión. La cuenta seguirá activa; intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    if (_token == null) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete-account'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (!mounted) return; // 👈 También va aquí antes de mostrar la SnackBar

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta eliminada exitosamente'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _token = null;
          _currentUser = null;
          _profile = null;
          _usernameController.clear();
          _passwordController.clear();
          _isPasswordVisible = false;
        });
        unawaited(AudioService.instance.detenerMusica());
        unawaited(SessionLifecycleService.instance.limpiarSesionActiva());
        try {
          await _sessionStorage.delete(key: _savedSessionKey);
        } catch (error) {
          _mostrarError(
            'La cuenta se eliminó, pero no se pudo borrar la sesión guardada.',
          );
        }
      }
    } catch (e) {
      _mostrarError('Error al eliminar la cuenta');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final profile =
        _profile ??
        const PlayerProfile(
          rankedPoints: eloInicial,
          rankedLevel: 'Nuevo héroe',
          gamesPlayed: 0,
          wins: 0,
          currentStreak: 0,
        );

    Widget statTile(String label, String value, IconData icon, Color color) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: esOscuro ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      key: const ValueKey('player-profile-card'),
      elevation: 3,
      color: esOscuro
          ? Colors.grey.shade900.withValues(alpha: 0.88)
          : Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: esOscuro ? Colors.amber.shade300 : Colors.amber.shade700,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: esOscuro
                      ? Colors.amber.shade300
                      : Colors.amber.shade800,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${profile.rankedLevel} · ${profile.rankedPoints} pts',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                statTile(
                  'Partidas',
                  '${profile.gamesPlayed}',
                  Icons.sports_esports_outlined,
                  Colors.blue,
                ),
                statTile(
                  'Victorias',
                  '${profile.wins}',
                  Icons.military_tech_outlined,
                  Colors.green,
                ),
                statTile(
                  'Racha',
                  '${profile.currentStreak}',
                  Icons.local_fire_department,
                  Colors.deepOrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // VISTA CUANDO EL USUARIO YA ESTÁ AUTENTICADO
    if (_token != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Jugador'),
          actions: const [AudioSettingsButton()],
        ),
        body: AppBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade900.withValues(alpha: 0.90)
                            : Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Bienvenido, $_currentUser!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProfileCard(context),
                    const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () async {
                    unawaited(AudioService.instance.reproducirSelect());
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InicioScreen()),
                    );
                    if (mounted) {
                      unawaited(AudioService.instance.reproducirMusicaMenu());
                      if (_token != null) {
                        unawaited(_cargarPerfilJugador(_token!));
                      }
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'Jugar sin conexión',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    unawaited(AudioService.instance.reproducirSelect());
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LobbyScreen(
                          token: _token!,
                          username: _currentUser!,
                        ),
                      ),
                    );
                    if (mounted) {
                      unawaited(AudioService.instance.reproducirMusicaMenu());
                      if (_token != null) {
                        unawaited(_cargarPerfilJugador(_token!));
                      }
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Crear sala'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    unawaited(AudioService.instance.reproducirSelect());
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LobbyScreen(
                          token: _token!,
                          username: _currentUser!,
                          joinMode: true,
                        ),
                      ),
                    );
                    if (mounted) {
                      unawaited(AudioService.instance.reproducirMusicaMenu());
                      if (_token != null) {
                        unawaited(_cargarPerfilJugador(_token!));
                      }
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Unirse a sala'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const ValueKey('game-modes-info-button'),
                  onPressed: () => mostrarReglasModosJuego(context),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Reglas y modos de juego'),
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xEB2B1818)
                      : Colors.white.withValues(alpha: 0.94),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                onPressed: () {
                  unawaited(AudioService.instance.reproducirSelect());
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('¿Borrar cuenta?'),
                      content: const Text(
                        'Esta acción es irreversible y perderás tu progreso.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            unawaited(AudioService.instance.reproducirBack());
                            Navigator.pop(context);
                          },
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            unawaited(AudioService.instance.reproducirSelect());
                            Navigator.pop(context);
                            _deleteAccount();
                          },
                          child: const Text('Borrar permanentemente'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text('Borrar mi cuenta'),
              ),
              const SizedBox(height: 10),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.blueGrey.shade800,
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        unawaited(AudioService.instance.reproducirBack());
                        _logout();
                      },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
              ),
            ),
          ),
        ),
      );
    }

    // VISTA DE LOGIN / REGISTRO
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _isLogin
        ? (esOscuro ? Colors.lightBlue.shade300 : Colors.blue.shade700)
        : (esOscuro ? Colors.tealAccent.shade200 : Colors.teal.shade700);
    final buttonColor = _isLogin ? Colors.blue.shade700 : Colors.teal.shade600;
    final cardBg = esOscuro
        ? Colors.grey.shade900.withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.94);
    final pillBg = _isLogin
        ? (esOscuro
              ? Colors.blue.shade900.withValues(alpha: 0.55)
              : Colors.blue.shade50)
        : (esOscuro
              ? Colors.teal.shade900.withValues(alpha: 0.55)
              : Colors.teal.shade50);
    final inactiveTabText = esOscuro ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Iniciar Sesión' : 'Crear Cuenta'),
        centerTitle: true,
        actions: const [AudioSettingsButton()],
      ),
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selector visual claro entre Entrar y Registrarse
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: esOscuro
                            ? Colors.black.withValues(alpha: 0.45)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              key: const ValueKey('auth-tab-login'),
                              onTap: _isLogin
                                  ? null
                                  : () {
                                      unawaited(
                                        AudioService.instance
                                            .reproducirSelect(),
                                      );
                                      setState(() => _isLogin = true);
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _isLogin
                                      ? Colors.blue.shade700
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.login_rounded,
                                      size: 18,
                                      color: _isLogin
                                          ? Colors.white
                                          : inactiveTabText,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Entrar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isLogin
                                            ? Colors.white
                                            : inactiveTabText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              key: const ValueKey('auth-tab-register'),
                              onTap: !_isLogin
                                  ? null
                                  : () {
                                      unawaited(
                                        AudioService.instance
                                            .reproducirSelect(),
                                      );
                                      setState(() => _isLogin = false);
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isLogin
                                      ? Colors.teal.shade600
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_add_alt_1_rounded,
                                      size: 18,
                                      color: !_isLogin
                                          ? Colors.white
                                          : inactiveTabText,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Registrarse',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: !_isLogin
                                            ? Colors.white
                                            : inactiveTabText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Column(
                        key: ValueKey<bool>(_isLogin),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: pillBg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _isLogin
                                  ? Icons.login_rounded
                                  : Icons.person_add_alt_1_rounded,
                              size: 40,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isLogin ? 'MODO ACCESO' : 'REGISTRO NUEVO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isLogin
                                ? 'Ingresa con tu cuenta existente para continuar tu progreso.'
                                : 'Crea un usuario nuevo para guardar tu rango, partidas y victorias.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: esOscuro ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: _isLogin
                            ? 'Usuario'
                            : 'Elige un nombre de usuario',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: _isLogin
                            ? 'Contraseña'
                            : 'Crea una contraseña',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          tooltip: _isPasswordVisible
                              ? 'Ocultar contraseña'
                              : 'Mostrar contraseña',
                          onPressed: () {
                            unawaited(
                              AudioService.instance.reproducirSelect(),
                            );
                            setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            );
                          },
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                unawaited(
                                  AudioService.instance.reproducirSelect(),
                                );
                                _submit();
                              },
                              icon: Icon(
                                _isLogin
                                    ? Icons.login_rounded
                                    : Icons.person_add_alt_1_rounded,
                              ),
                              label: Text(
                                _isLogin ? 'INGRESAR' : 'REGISTRARSE',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        unawaited(AudioService.instance.reproducirSelect());
                        setState(() => _isLogin = !_isLogin);
                      },
                      child: Text(
                        _isLogin
                            ? '¿No tienes cuenta? Regístrate'
                            : '¿Ya tienes cuenta? Inicia sesión',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
