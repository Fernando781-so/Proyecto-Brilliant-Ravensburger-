import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_config.dart';
import 'inicio_screen.dart';
import 'lobby_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const FlutterSecureStorage _sessionStorage = FlutterSecureStorage();
  static const String _savedSessionKey = 'auth_session';

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _token;
  String? _currentUser;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    try {
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
        setState(() {
          _token = savedToken;
          _currentUser = savedUsername;
        });
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
            setState(() {
              _token = token;
              _currentUser = username;
            });
            _mostrarError(
              'No se pudo guardar la sesión en este dispositivo. '
              'Cierra sesión antes de salir.',
            );
            return;
          }
          if (!mounted) return;
          setState(() {
            _token = token;
            _currentUser = username;
          });
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
          _usernameController.clear();
          _passwordController.clear();
          _isPasswordVisible = false;
        });
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
          _usernameController.clear();
          _passwordController.clear();
          _isPasswordVisible = false;
        });
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

  @override
  Widget build(BuildContext context) {
    // VISTA CUANDO EL USUARIO YA ESTÁ AUTENTICADO
    if (_token != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel de Jugador')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bienvenido, $_currentUser!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InicioScreen()),
                    );
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
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LobbyScreen(
                          token: _token!,
                          username: _currentUser!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Crear sala'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LobbyScreen(
                          token: _token!,
                          username: _currentUser!,
                          joinMode: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Unirse a sala'),
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('¿Borrar cuenta?'),
                      content: const Text(
                        'Esta acción es irreversible y perderás tu progreso.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
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
                onPressed: _isLoading ? null : _logout,
                child: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // VISTA DE LOGIN / REGISTRO
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Iniciar Sesión' : 'Crear Cuenta'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // <--- Agregado para evitar desbordamiento
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.casino, size: 80, color: Colors.blue.shade700),
              const SizedBox(height: 30),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration:
                    const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ).copyWith(
                      suffixIcon: IconButton(
                        tooltip: _isPasswordVisible
                            ? 'Ocultar contraseña'
                            : 'Mostrar contraseña',
                        onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _submit,
                        child: Text(
                          _isLogin ? 'INGRESAR' : 'REGISTRARSE',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
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
    );
  }
}
