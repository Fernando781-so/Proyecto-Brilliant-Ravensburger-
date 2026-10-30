import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'inicio_screen.dart';

// REEMPLAZA ESTA URL CON TU URL DE NGROK O RENDER
const String baseUrl = 'https://tu-url-de-ngrok.app/api'; 

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  String? _token;
  String? _currentUser;

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'], style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
        
        if (_isLogin) {
          setState(() {
            _token = data['token'];
            _currentUser = _usernameController.text.trim();
          });
        } else {
          // Si se registró, cambiar a modo login
          setState(() => _isLogin = true);
        }
      } else {
        _mostrarError(data['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      _mostrarError('Error de conexión con el servidor');
    } finally {
      setState(() => _isLoading = false);
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

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta eliminada exitosamente'), backgroundColor: Colors.orange),
        );
        setState(() {
          _token = null;
          _currentUser = null;
          _usernameController.clear();
          _passwordController.clear();
        });
      }
    } catch (e) {
      _mostrarError('Error al eliminar la cuenta');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
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
              Text('Bienvenido, $_currentUser!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const InicioScreen()),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('JUGAR AHORA', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('¿Borrar cuenta?'),
                      content: const Text('Esta acción es irreversible y perderás tu progreso.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
                onPressed: () => setState(() { _token = null; _currentUser = null; }),
                child: const Text('Cerrar sesión', style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      );
    }

    // VISTA DE LOGIN / REGISTRO
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Iniciar Sesión' : 'Crear Cuenta'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.casino, size: 80, color: Colors.blue.shade700),
            const SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Usuario', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
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
                      child: Text(_isLogin ? 'INGRESAR' : 'REGISTRARSE', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }
}