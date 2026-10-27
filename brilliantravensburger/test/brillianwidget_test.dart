import 'package:brilliantravensburger/inicio_screen.dart';
import 'package:brilliantravensburger/brilliantravensburger.dart';
import 'package:brilliantravensburger/juego_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _colocarNumero(WidgetTester tester, int numero) async {
  await tester.tap(find.text('+').first);
  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(ElevatedButton, '$numero'));
  await tester.pumpAndSettle();
}

Future<void> _elegirTablero(WidgetTester tester, [int numero = 1]) async {
  await tester.tap(find.text('Tablero $numero'));
  await tester.pumpAndSettle();
}

Future<void> _iniciarPartida(WidgetTester tester, [int tablero = 1]) async {
  await _elegirTablero(tester, tablero);
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

Future<void> _jugarPrimerMovimientoDisponible(WidgetTester tester) async {
  for (var intento = 0; intento < 100; intento++) {
    if (find.text('Sin movimientos').evaluate().isNotEmpty) {
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      continue;
    }

    if (find
        .byWidgetPredicate(
          (widget) =>
              widget is Text &&
              RegExp(r'^\+[1-6]$').hasMatch(widget.data ?? ''),
        )
        .evaluate()
        .isNotEmpty) {
      await tester.tap(_primeraCasillaValida());
      await tester.pumpAndSettle();
      expect(find.text('¡Número Colocado!'), findsOneWidget);

      await tester.tap(find.text('Avanzar Turno'));
      await tester.pumpAndSettle();
      return;
    }

    await tester.pumpAndSettle();
  }

  fail('No se encontró un movimiento válido después de 100 turnos.');
}

void _configurarSuperficie(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('permite elegir entre cuatro tableros antes de colocar números', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));

    expect(find.text('Elige un tablero'), findsOneWidget);
    for (var numero = 1; numero <= 4; numero++) {
      expect(find.text('Tablero $numero'), findsOneWidget);
      expect(
        find.byKey(ValueKey('vista-previa-tablero-$numero')),
        findsOneWidget,
      );
    }
    expect(find.text('Configuración de inicio'), findsNothing);

    await _elegirTablero(tester, 3);

    expect(find.text('Configuración de inicio'), findsOneWidget);
    expect(find.text('Tablero 3'), findsOneWidget);
    expect(find.text('Brilliant - Posiciones Iniciales'), findsOneWidget);
    expect(find.text('+'), findsNWidgets(6));
    expect(find.text('COLOCA LOS 6 NÚMEROS'), findsOneWidget);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is ElevatedButton && widget.onPressed == null,
      ),
      findsOneWidget,
    );
  });

  testWidgets('muestra el tablero inicial y bloquea el avance', (tester) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));
    await _elegirTablero(tester);

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
    await _elegirTablero(tester);

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
    await _elegirTablero(tester);

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
    await _elegirTablero(tester);

    await _colocarNumero(tester, 1);
    await tester.tap(find.text('+').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, '1'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('+'), findsNWidgets(5));
    expect(find.text('💥 ¡El número 1 cambió de casilla!'), findsOneWidget);
  });

  for (final numeroTablero in [2, 3, 4]) {
    testWidgets(
      'permite iniciar y jugar un turno en el tablero $numeroTablero',
      (tester) async {
        _configurarSuperficie(tester);
        await tester.pumpWidget(const MaterialApp(home: InicioScreen()));

        await _iniciarPartida(tester, numeroTablero);

        expect(
          find.text('Brilliant - Tablero $numeroTablero - Turno 1'),
          findsOneWidget,
        );
        expect(find.textContaining('Ancla:'), findsOneWidget);

        await _jugarPrimerMovimientoDisponible(tester);

        expect(
          find.text('Brilliant - Tablero $numeroTablero - Turno 2'),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('permite quitar un número y volver a la configuración inicial', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));
    await _elegirTablero(tester);

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

      await _iniciarPartida(tester, 3);

      expect(find.text('Brilliant - Tablero 3 - Turno 1'), findsOneWidget);
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
      expect(find.text('Brilliant - Tablero 3 - Turno 1'), findsOneWidget);

      await tester.tap(_primeraCasillaValida());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avanzar Turno'));
      await tester.pumpAndSettle();
      expect(find.text('Brilliant - Tablero 3 - Turno 2'), findsOneWidget);

      await tester.tap(find.text('SALTAR TURNO'));
      await tester.pumpAndSettle();
      expect(find.text('¿Saltar turno?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Brilliant - Tablero 3 - Turno 2'), findsOneWidget);

      await tester.tap(find.text('SALTAR TURNO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, saltar turno'));
      await tester.pumpAndSettle();
      expect(find.text('Brilliant - Tablero 3 - Turno 3'), findsOneWidget);
    },
  );

  testWidgets('explica al pasar el cursor si una casilla acepta el número', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    final celdas = List.generate(7, (_) => List.filled(7, 0));
    final posicionesOcupadas = [
      [2, 2],
      [2, 3],
      [2, 4],
      [3, 2],
      [3, 3],
      [3, 4],
    ];
    for (var i = 0; i < posicionesOcupadas.length; i++) {
      final posicion = posicionesOcupadas[i];
      celdas[posicion[0]][posicion[1]] = i + 1;
    }

    final tablero = Tablero(
      celdas: celdas,
      zonas: [
        Zona(
          region: Region.verde,
          posiciones: [
            for (var fila = 0; fila < 7; fila++)
              for (var columna = 0; columna < 7; columna++)
                [fila, columna],
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp(home: JuegoScreen(tablero: tablero)));
    await tester.pumpAndSettle();

    final casillaValida = find.byWidgetPredicate(
      (widget) =>
          widget is Tooltip &&
          widget.message?.startsWith('Puedes colocar el número') == true,
       );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(casillaValida.first));
    await mouse.moveTo(tester.getCenter(casillaValida.first));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Puedes colocar el número'), findsOneWidget);

    final casillaOcupada = find.byKey(const ValueKey('casilla-juego-2-2'));
    await mouse.moveTo(tester.getCenter(casillaOcupada));
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.textContaining('la casilla ya contiene el número 1'),
      findsOneWidget,
    );
    await mouse.removePointer();
  });

  testWidgets('finaliza una partida con el puntaje al llenar el tablero', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    final tablero = Tablero(
      celdas: List.generate(7, (_) => List.filled(7, 1)),
      zonas: zonas,
    );

    await tester.pumpWidget(MaterialApp(home: JuegoScreen(tablero: tablero)));
    await tester.pumpAndSettle();

    expect(find.text('¡Partida finalizada!'), findsOneWidget);
    expect(find.text('Puntaje total: 30 pts'), findsOneWidget);
    expect(find.text('Partida finalizada'), findsOneWidget);
    expect(find.text('Sin movimientos'), findsNothing);
  });
}
