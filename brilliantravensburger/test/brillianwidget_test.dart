import 'package:brilliantravensburger/inicio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _colocarNumero(WidgetTester tester, int numero) async {
  await tester.tap(find.text('+').first);
  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(ElevatedButton, '$numero'));
  await tester.pumpAndSettle();
}

Future<void> _iniciarPartida(WidgetTester tester) async {
  for (var numero = 1; numero <= 6; numero++) {
    await _colocarNumero(tester, numero);
  }

  await tester.tap(find.text('¡LISTO! AVANZAR'));
  await tester.pumpAndSettle();
}

Finder _primeraCasillaValida() {
  return find
      .byWidgetPredicate(
        (widget) =>
            widget is Text && RegExp(r'^\+[1-6]$').hasMatch(widget.data ?? ''),
      )
      .first;
}

void _configurarSuperficie(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('muestra el tablero inicial y bloquea el avance', (tester) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));

    expect(find.text('Brilliant - Posiciones Iniciales'), findsOneWidget);
    expect(find.text('Configuración de inicio'), findsOneWidget);
    expect(find.text('+'), findsNWidgets(6));
    expect(find.text('COLOCA LOS 6 NÚMEROS'), findsOneWidget);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is ElevatedButton && widget.onPressed == null,
      ),
      findsOneWidget,
    );
  });

  testWidgets('permite elegir un número desde una casilla inicial', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));

    await tester.tap(find.text('+').first);
    await tester.pumpAndSettle();

    expect(find.text('Selecciona o mueve un número'), findsOneWidget);
    for (var numero = 1; numero <= 6; numero++) {
      expect(find.widgetWithText(ElevatedButton, '$numero'), findsOneWidget);
    }

    await tester.tap(find.widgetWithText(ElevatedButton, '1'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('+'), findsNWidgets(5));
    expect(find.text('Selecciona o mueve un número'), findsNothing);
  });

  testWidgets('habilita el avance cuando se colocan los seis números', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));

    for (var numero = 1; numero <= 6; numero++) {
      await _colocarNumero(tester, numero);
    }

    expect(
      find.text('¡Todos los números colocados! Ya puedes iniciar.'),
      findsOneWidget,
    );
    expect(find.text('¡LISTO! AVANZAR'), findsOneWidget);
    expect(find.text('+'), findsNothing);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is ElevatedButton && widget.onPressed != null,
      ),
      findsOneWidget,
    );
  });

  testWidgets('permite mover un número ya colocado a otra casilla inicial', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));

    await _colocarNumero(tester, 1);
    await tester.tap(find.text('+').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, '1'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('+'), findsNWidgets(5));
    expect(find.text('💥 ¡El número 1 cambió de casilla!'), findsOneWidget);
  });

  testWidgets('permite quitar un número y volver a la configuración inicial', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));

    await _colocarNumero(tester, 1);
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar número'));
    await tester.pumpAndSettle();

    expect(find.text('+'), findsNWidgets(6));
    expect(find.text('COLOCA LOS 6 NÚMEROS'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets(
    'completa una partida, deshace y confirma una jugada y salta turno',
    (tester) async {
      _configurarSuperficie(tester);
      await tester.pumpWidget(const MaterialApp(home: InicioScreen()));

      await _iniciarPartida(tester);

      expect(find.text('Brilliant - Turno 1'), findsOneWidget);
      expect(
        find.text('🎲 Dados de la mesa (Lanzamiento Automático):'),
        findsOneWidget,
      );
      expect(find.textContaining('Ancla:'), findsOneWidget);

      await tester.tap(_primeraCasillaValida());
      await tester.pumpAndSettle();
      expect(find.text('¡Número Colocado!'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(find.text('¡Número Colocado!'), findsNothing);
      expect(find.text('Brilliant - Turno 1'), findsOneWidget);

      await tester.tap(_primeraCasillaValida());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avanzar Turno'));
      await tester.pumpAndSettle();
      expect(find.text('Brilliant - Turno 2'), findsOneWidget);

      await tester.tap(find.text('SALTAR TURNO'));
      await tester.pumpAndSettle();
      expect(find.text('¿Saltar turno?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Brilliant - Turno 2'), findsOneWidget);

      await tester.tap(find.text('SALTAR TURNO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, saltar turno'));
      await tester.pumpAndSettle();
      expect(find.text('Brilliant - Turno 3'), findsOneWidget);
    },
  );
}
