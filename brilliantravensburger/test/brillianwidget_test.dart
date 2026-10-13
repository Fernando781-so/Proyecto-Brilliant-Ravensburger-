import 'package:brilliantravensburger/inicio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _colocarNumero(WidgetTester tester, int numero) async {
  await tester.tap(find.text('+').first);
  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(ElevatedButton, '$numero'));
  await tester.pumpAndSettle();
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
}
