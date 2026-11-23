import 'package:flutter/material.dart';

/// Servicio global para alternar el color del fondo de la aplicación entre blanco y negro.
class ThemeService extends ChangeNotifier {
  ThemeService._();

  static final ThemeService instance = ThemeService._();

  bool _fondoOscuro = false;

  bool get esFondoOscuro => _fondoOscuro;
  ThemeMode get themeMode => _fondoOscuro ? ThemeMode.dark : ThemeMode.light;
  Color get colorFondo => _fondoOscuro ? Colors.black : Colors.white;

  void establecerFondoOscuro(bool oscuro) {
    if (_fondoOscuro == oscuro) return;
    _fondoOscuro = oscuro;
    notifyListeners();
  }

  void alternarFondo() => establecerFondoOscuro(!_fondoOscuro);

  @visibleForTesting
  void reiniciarEstadoParaPruebas() {
    _fondoOscuro = false;
  }
}
