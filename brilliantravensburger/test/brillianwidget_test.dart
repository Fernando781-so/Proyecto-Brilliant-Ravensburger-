import 'package:brilliantravensburger/inicio_screen.dart';
import 'package:brilliantravensburger/brilliantravensburger.dart';
import 'package:brilliantravensburger/juego_screen.dart';
import 'package:brilliantravensburger/multiplayer_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMultiplayerService implements MultiplayerService {
  _FakeMultiplayerService({required this.room, required this.game});

  final Set<VoidCallback> _listeners = {};
  bool turnComplete = false;
  bool boardComplete = false;

  @override
  MultiplayerRoom? room;

  @override
  MultiplayerGameState? game;

  @override
  String? playerId = 'player-top';

  @override
  String? lastError;

  @override
  bool get isConnected => true;

  @override
  bool get canPlay => true;

  @override
  int get myScore => 30;

  @override
  List<int>? get myBoard => null;

  @override
  bool get myTurnIsComplete => turnComplete;

  @override
  bool get myBoardIsComplete => boardComplete;

  @override
  bool get mySetupIsComplete =>
      game?.setupCompletePlayerIds.contains(playerId) ?? false;

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  void dispose() => _listeners.clear();

  @override
  Future<void> completeTurn({
    required List<int> board,
    required List<int> completedZones,
    required bool finished,
  }) async {
    turnComplete = true;
    boardComplete = finished;
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  @override
  void notifyListeners() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
      expect(find.text('Avanzar Turno'), findsOneWidget);

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

  testWidgets('muestra las reglas y símbolos durante la colocación inicial', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));
    await _elegirTablero(tester, 3);

    await tester.tap(find.byTooltip('Ver reglas del tablero 3'));
    await tester.pumpAndSettle();

    expect(find.text('Reglas del tablero 3'), findsOneWidget);
    expect(find.text('Reglas por color y zona'), findsOneWidget);
    expect(find.textContaining('Morado · Zonas'), findsOneWidget);
    expect(find.textContaining('Rojo · Zonas'), findsOneWidget);
    expect(find.textContaining('Blanco · Zona'), findsOneWidget);
    expect(find.textContaining('Gris'), findsNothing);
    expect(find.text('XO'), findsOneWidget);
    expect(
      find.text('La zona debe contener exactamente dos números distintos.'),
      findsOneWidget,
    );
  });

  testWidgets('describe todas las zonas agrupadas del tablero 4', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));
    await _elegirTablero(tester, 4);

    await tester.tap(find.byTooltip('Ver reglas del tablero 4'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Morado · Zona'), findsOneWidget);
    expect(find.textContaining('Azul · Zona'), findsOneWidget);
    expect(find.textContaining('Rojo · Zonas'), findsOneWidget);
    expect(find.textContaining('Naranja 1-3 · Zona'), findsOneWidget);
    expect(find.textContaining('Naranja 4-6 · Zona'), findsOneWidget);
    expect(find.textContaining('Amarillo · Zona'), findsOneWidget);
    expect(find.textContaining('Verde · Zona'), findsOneWidget);
    expect(find.text('≠'), findsNWidgets(2));
    expect(find.text('1-3'), findsOneWidget);
    expect(find.text('4-6'), findsOneWidget);
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

  testWidgets('abre la configuración con el tablero indicado y luego inicia', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(
      const MaterialApp(home: InicioScreen(tableroInicial: 2)),
    );

    expect(find.text('Brilliant - Posiciones Iniciales'), findsOneWidget);
    expect(find.text('Tablero 2'), findsOneWidget);
    expect(find.text('Elige un tablero'), findsNothing);
    expect(find.text('+'), findsNWidgets(6));

    for (var numero = 1; numero <= 6; numero++) {
      await _colocarNumero(tester, numero);
    }

    await tester.tap(find.text('¡LISTO! AVANZAR'));
    await tester.pumpAndSettle();

    expect(find.text('Brilliant - Tablero 2 - Turno 1'), findsOneWidget);
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
        expect(find.textContaining('Ancla:'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('drawer-tab-instructions')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Ancla:'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('drawer-tab-instructions')));
        await tester.pumpAndSettle();

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
      expect(find.textContaining('Ancla:'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('drawer-tab-instructions')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ancla:'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('drawer-tab-instructions')));
      await tester.pumpAndSettle();

      await tester.tap(_primeraCasillaValida());
      await tester.pumpAndSettle();
      expect(find.text('Avanzar Turno'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(find.text('Avanzar Turno'), findsNothing);
      expect(find.text('SALTAR TURNO'), findsOneWidget);
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
              for (var columna = 0; columna < 7; columna++) [fila, columna],
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

  testWidgets('muestra reglas y premios de cada zona del tablero', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));

    await _iniciarPartida(tester, 4);
    await _jugarPrimerMovimientoDisponible(tester);
    for (var intento = 0; intento < 100; intento++) {
      if (find.text('Sin movimientos').evaluate().isEmpty) break;
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Puntos por zona'), findsNothing);
    expect(find.byKey(const ValueKey('placement-guide')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('drawer-tab-instructions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drawer-backdrop')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('instructions-drawer-list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reglas por color y zona'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('drawer-tab-instructions')),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
    final board = crearTablero(4);
    final upperOrangeIndex = board.zonas.indexWhere(
      (zone) => zone.region == Region.naranja && zone.valorMinimo == 4,
    );
    expect(upperOrangeIndex, isNonNegative);
    final upperOrangeLabel = find.textContaining('Naranja 4-6 · Zona');
    expect(upperOrangeLabel, findsOneWidget);
    expect(find.text('La zona acepta números del 4 al 6.'), findsOneWidget);

    final lowerOrangeLabel = find.textContaining('Naranja 1-3 · Zona');
    await tester.ensureVisible(lowerOrangeLabel);
    expect(lowerOrangeLabel, findsOneWidget);
    await tester.ensureVisible(find.textContaining('Morado ·'));
    expect(
      find.text('La zona debe contener exactamente dos números distintos.'),
      findsOneWidget,
    );
    expect(find.textContaining('Zona '), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('drawer-tab-instructions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drawer-backdrop')), findsNothing);
    expect(find.text('Puntos por zona'), findsNothing);
  });

  testWidgets('no entra al juego sin confirmar sus números iniciales', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    final service = _FakeMultiplayerService(
      room: MultiplayerRoom(
        code: 'ROOM01',
        hostId: 'player-host',
        capacity: 2,
        boardId: 2,
        targetPoints: 20,
        status: 'playing',
        players: const [
          MultiplayerPlayer(
            id: 'player-host',
            username: 'Anfitrión',
            ready: true,
            connected: true,
            score: 0,
            finished: false,
            setupComplete: true,
          ),
          MultiplayerPlayer(
            id: 'player-mobile',
            username: 'Invitado',
            ready: true,
            connected: true,
            score: 0,
            finished: false,
            setupComplete: false,
          ),
        ],
      ),
      game: const MultiplayerGameState(
        turn: 1,
        dice: [2, 5],
        phase: 'playing',
        setupCompletePlayerIds: {'player-host'},
        completedPlayerIds: {},
        zoneClaims: {},
        winnerId: null,
      ),
    )..playerId = 'player-mobile';

    await tester.pumpWidget(
      MaterialApp(home: InicioScreen(tableroInicial: 2, multiplayer: service)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Coloca tus 6 números iniciales para completar la configuración.',
      ),
      findsOneWidget,
    );
    expect(find.text('COLOCA LOS 6 NÚMEROS'), findsOneWidget);
    expect(find.text('Brilliant - Tablero 2 - Turno 1'), findsNothing);
  });

  testWidgets('muestra conectados por puntaje y las zonas capturadas', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    final service = _FakeMultiplayerService(
      room: MultiplayerRoom(
        code: 'ROOM01',
        hostId: 'player-top',
        capacity: 4,
        boardId: 4,
        targetPoints: 30,
        status: 'playing',
        players: const [
          MultiplayerPlayer(
            id: 'player-top',
            username: 'Ana',
            ready: true,
            connected: true,
            score: 30,
            finished: false,
            setupComplete: true,
          ),
          MultiplayerPlayer(
            id: 'player-second',
            username: 'Luis',
            ready: true,
            connected: true,
            score: 20,
            finished: false,
            setupComplete: true,
          ),
          MultiplayerPlayer(
            id: 'player-third',
            username: 'Mia',
            ready: true,
            connected: true,
            score: 10,
            finished: false,
            setupComplete: true,
          ),
          MultiplayerPlayer(
            id: 'player-offline',
            username: 'Fuera',
            ready: true,
            connected: false,
            score: 99,
            finished: false,
            setupComplete: true,
          ),
        ],
      ),
      game: const MultiplayerGameState(
        turn: 1,
        dice: [1, 2],
        phase: 'playing',
        setupCompletePlayerIds: {'player-top', 'player-second', 'player-third'},
        completedPlayerIds: {},
        zoneClaims: {
          0: [
            {'playerId': 'player-top', 'username': 'Ana', 'points': 6},
            {'playerId': 'player-second', 'username': 'Luis', 'points': 4},
          ],
          3: [
            {'playerId': 'player-third', 'username': 'Mia', 'points': 5},
          ],
        },
        winnerId: null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: JuegoScreen(tablero: crearTablero(4), multiplayer: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jugadores conectados y zonas capturadas'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('drawer-tab-players')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('drawer-tab-players')),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('drawer-tab-players')),
        matching: find.byIcon(Icons.groups_outlined),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('drawer-backdrop')), findsOneWidget);
    final menu = find.text('Jugadores conectados y zonas capturadas');
    await tester.ensureVisible(menu);

    expect(find.text('3 conectados · 2 zonas · Meta: 30 pts'), findsOneWidget);
    expect(find.text('Fuera'), findsNothing);
    expect(find.text('Zonas capturadas (2)'), findsOneWidget);
    for (final (playerId, rank) in [
      ('player-top', '1.er lugar'),
      ('player-second', '2.º lugar'),
      ('player-third', '3.er lugar'),
    ]) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('connected-player-$playerId')),
          matching: find.text(rank),
        ),
        findsOneWidget,
      );
    }
    expect(find.textContaining('Zona 1 ·'), findsOneWidget);
    expect(find.text('+6 pts'), findsOneWidget);
    expect(find.text('+4 pts'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('drawer-backdrop')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drawer-backdrop')), findsNothing);
    expect(find.text('Jugadores conectados y zonas capturadas'), findsNothing);
  });

  testWidgets('deshabilita deshacer después de enviar el turno', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    final board = crearTablero(1);
    final initialPositions = obtenerPosicionesInicialesTablero(1);
    for (var index = 0; index < initialPositions.length; index++) {
      final position = initialPositions[index];
      board.celdas[position[0]][position[1]] = index + 1;
    }

    var dice = <int>[];
    for (var first = 1; first <= 6 && dice.isEmpty; first++) {
      for (var second = 1; second <= 6; second++) {
        if (obtenerPosicionesValidas(board, first, second).isNotEmpty ||
            obtenerPosicionesValidas(board, second, first).isNotEmpty) {
          dice = [first, second];
          break;
        }
      }
    }
    expect(dice, hasLength(2));

    final service = _FakeMultiplayerService(
      room: MultiplayerRoom(
        code: 'ROOM01',
        hostId: 'player-top',
        capacity: 2,
        boardId: 1,
        targetPoints: 20,
        status: 'playing',
        players: const [
          MultiplayerPlayer(
            id: 'player-top',
            username: 'Ana',
            ready: true,
            connected: true,
            score: 0,
            finished: false,
            setupComplete: true,
          ),
        ],
      ),
      game: MultiplayerGameState(
        turn: 1,
        dice: dice,
        phase: 'playing',
        setupCompletePlayerIds: const {'player-top'},
        completedPlayerIds: const {},
        zoneClaims: const {},
        winnerId: null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: JuegoScreen(tablero: board, multiplayer: service),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_primeraCasillaValida());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avanzar Turno'));
    await tester.pumpAndSettle();

    expect(find.text('ESPERANDO A LOS JUGADORES'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('undo-move-button')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('notifica la captura de una zona a los jugadores', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    final service = _FakeMultiplayerService(
      room: MultiplayerRoom(
        code: 'ROOM01',
        hostId: 'player-top',
        capacity: 2,
        boardId: 1,
        targetPoints: 20,
        status: 'playing',
        players: const [
          MultiplayerPlayer(
            id: 'player-top',
            username: 'Ana',
            ready: true,
            connected: true,
            score: 0,
            finished: false,
            setupComplete: true,
          ),
        ],
      ),
      game: const MultiplayerGameState(
        turn: 1,
        dice: [2, 5],
        phase: 'playing',
        setupCompletePlayerIds: {'player-top'},
        completedPlayerIds: {},
        zoneClaims: {},
        winnerId: null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: JuegoScreen(tablero: crearTablero(1), multiplayer: service),
      ),
    );
    await tester.pumpAndSettle();
    service.game = const MultiplayerGameState(
      turn: 1,
      dice: [2, 5],
      phase: 'playing',
      setupCompletePlayerIds: {'player-top'},
      completedPlayerIds: {},
      zoneClaims: {
        0: [
          {'playerId': 'player-top', 'username': 'Ana', 'points': 8},
        ],
      },
      winnerId: null,
    );
    service.notifyListeners();
    await tester.pumpAndSettle();

    expect(find.text('Ana tomó la Zona 1 (Amarillo).'), findsOneWidget);
  });

  testWidgets('finaliza y no puntúa la zona amarilla con números repetidos', (
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
    expect(find.text('Puntaje total: 22 pts'), findsOneWidget);
    expect(find.text('Partida finalizada'), findsOneWidget);
    expect(find.text('Sin movimientos'), findsNothing);
  });

  testWidgets('muestra los tableros compartidos al terminar la partida', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    final service = _FakeMultiplayerService(
      room: MultiplayerRoom(
        code: 'ROOM01',
        hostId: 'player-top',
        capacity: 2,
        boardId: 2,
        targetPoints: 20,
        status: 'finished',
        players: [
          MultiplayerPlayer(
            id: 'player-top',
            username: 'Ana',
            ready: true,
            connected: true,
            score: 30,
            finished: true,
            setupComplete: true,
            board: List<int>.filled(49, 1),
          ),
          MultiplayerPlayer(
            id: 'player-second',
            username: 'Luis',
            ready: true,
            connected: true,
            score: 20,
            finished: true,
            setupComplete: true,
            board: List<int>.filled(49, 2),
          ),
        ],
      ),
      game: const MultiplayerGameState(
        turn: 8,
        dice: [2, 5],
        phase: 'finished',
        setupCompletePlayerIds: {'player-top', 'player-second'},
        completedPlayerIds: {'player-top', 'player-second'},
        zoneClaims: {},
        winnerId: 'player-top',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: JuegoScreen(tablero: crearTablero(2), multiplayer: service),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver tableros'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('final-board-player-top')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('final-board-player-second')),
      findsOneWidget,
    );
  });

  testWidgets('permite alternar entre tableros individuales y la lista', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    final service = _FakeMultiplayerService(
      room: MultiplayerRoom(
        code: 'ROOM01',
        hostId: 'player-top',
        capacity: 2,
        boardId: 2,
        targetPoints: 20,
        status: 'finished',
        players: [
          MultiplayerPlayer(
            id: 'player-top',
            username: 'Ana',
            ready: true,
            connected: true,
            score: 30,
            finished: true,
            setupComplete: true,
            board: List<int>.filled(49, 1),
          ),
          MultiplayerPlayer(
            id: 'player-second',
            username: 'Luis',
            ready: true,
            connected: true,
            score: 20,
            finished: true,
            setupComplete: true,
            board: List<int>.filled(49, 2),
          ),
        ],
      ),
      game: const MultiplayerGameState(
        turn: 8,
        dice: [2, 5],
        phase: 'finished',
        setupCompletePlayerIds: {'player-top', 'player-second'},
        completedPlayerIds: {'player-top', 'player-second'},
        zoneClaims: {},
        winnerId: 'player-top',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: JuegoScreen(tablero: crearTablero(2), multiplayer: service),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver tableros'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('select-final-board-player-top')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('final-board-detail-player-top')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('final-board-player-second')),
      findsNothing,
    );

    await tester.tap(find.text('Volver a los tableros'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('final-board-player-second')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('select-final-board-player-second')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('final-board-detail-player-second')),
      findsOneWidget,
    );
  });
}
