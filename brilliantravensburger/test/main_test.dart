import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brilliantravensburger/lobby_screen.dart';
import 'package:brilliantravensburger/main.dart' as app;
import 'package:brilliantravensburger/theme_service.dart';

void main() {
  setUp(() {
    ThemeService.instance.reiniciarEstadoParaPruebas();
  });

  testWidgets('main opens the illustrative welcome screen before sign-in', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('BRILLIANT'), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-login-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('welcome-register-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('welcome-login-button')));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('INGRESAR'), findsOneWidget);
  });

  testWidgets('authentication screen switches to registration mode', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('welcome-login-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
    await tester.pumpAndSettle();

    expect(find.text('Crear Cuenta'), findsOneWidget);
    expect(find.text('REGISTRARSE'), findsOneWidget);
  });

  testWidgets('password visibility can be toggled', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('welcome-login-button')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
  });

  testWidgets('permite cambiar el color del fondo entre blanco y negro', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(ThemeService.instance.esFondoOscuro, isFalse);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );

    await tester.tap(find.byKey(const ValueKey('audio-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Color del fondo'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fondo-negro-button')));
    await tester.pumpAndSettle();

    expect(ThemeService.instance.esFondoOscuro, isTrue);
    expect(ThemeService.instance.colorFondo, Colors.black);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await tester.tap(find.byKey(const ValueKey('fondo-blanco-button')));
    await tester.pumpAndSettle();

    expect(ThemeService.instance.esFondoOscuro, isFalse);
    expect(ThemeService.instance.colorFondo, Colors.white);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  testWidgets('lobby creation mode only shows room configuration', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LobbyScreen(token: 'token', username: 'Jugador'),
      ),
    );

    expect(find.text('Crear sala'), findsOneWidget);
    expect(find.text('Cantidad de jugadores'), findsOneWidget);
    expect(find.text('Código de sala'), findsNothing);
    expect(find.text('Jugar sin conexión'), findsNothing);
  });

  testWidgets('lobby join mode only shows room code entry', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LobbyScreen(token: 'token', username: 'Jugador', joinMode: true),
      ),
    );

    expect(find.text('Unirse a sala'), findsOneWidget);
    expect(find.text('Código de sala'), findsOneWidget);
    expect(find.text('Cantidad de jugadores'), findsNothing);
    expect(find.text('Crear sala'), findsNothing);
  });
}
