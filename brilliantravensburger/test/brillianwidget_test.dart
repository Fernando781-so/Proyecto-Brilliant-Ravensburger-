import 'package:brilliantravensburger/audio_service.dart';
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
  bool connected = true;
  bool playAllowed = true;
  int ownScore = 30;
  int leaveCalls = 0;
  int disposeCalls = 0;
  int completeTurnCalls = 0;
  List<int>? lastSubmittedBoard;
  int completeSetupCalls = 0;

  @override
  MultiplayerRoom? room;

  @override
  MultiplayerGameState? game;

  @override
  String? playerId = 'player-top';

  @override
  String? lastError;

  @override
  bool get isConnected => connected;

  @override
  bool get canPlay => playAllowed;

  @override
  int get myScore => ownScore;

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
  void dispose() {
    disposeCalls++;
    _listeners.clear();
  }

  @override
  Future<void> leaveRoom() async {
    leaveCalls++;
    room = null;
    game = null;
  }

  @override
  Future<void> completeTurn({
    required List<int> board,
    required List<int> completedZones,
    required bool finished,
  }) async {
    completeTurnCalls++;
    lastSubmittedBoard = List<int>.of(board);
    turnComplete = true;
    boardComplete = finished;
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  @override
  Future<void> completeInitialSetup({required List<int> board}) async {
    completeSetupCalls++;
    lastSubmittedBoard = List<int>.of(board);
    game = MultiplayerGameState(
      turn: game?.turn ?? 1,
      dice: game?.dice ?? const [1, 2],
      phase: game?.phase ?? 'setup',
      setupCompletePlayerIds: {
        ...?game?.setupCompletePlayerIds,
        if (playerId != null) playerId!,
      },
      completedPlayerIds: game?.completedPlayerIds ?? const {},
      zoneClaims: game?.zoneClaims ?? const {},
      winnerId: game?.winnerId,
    );
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

  testWidgets('muestra los puntos de cada zona durante la configuración', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));
    await _elegirTablero(tester, 3);

    await tester.tap(find.byTooltip('Ver reglas del tablero 3'));
    await tester.pumpAndSettle();

    expect(find.text('Reglas del tablero 3'), findsOneWidget);
    expect(find.text('Puntos de las zonas'), findsOneWidget);
    final board = crearTablero(3);
    for (var index = 0; index < board.zonas.length; index++) {
      expect(find.byKey(ValueKey('board-zone-${index + 1}')), findsOneWidget);
    }
    expect(find.textContaining('Gris'), findsNothing);
    expect(find.textContaining('Puntos: '), findsWidgets);
    expect(find.text('Reglas por color y zona'), findsNothing);
  });

  testWidgets('muestra los puntos de todas las zonas del tablero 4', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    await tester.pumpWidget(const MaterialApp(home: InicioScreen()));
    await _elegirTablero(tester, 4);

    await tester.tap(find.byTooltip('Ver reglas del tablero 4'));
    await tester.pumpAndSettle();

    final board = crearTablero(4);
    for (var index = 0; index < board.zonas.length; index++) {
      expect(find.byKey(ValueKey('board-zone-${index + 1}')), findsOneWidget);
      final zone = board.zonas[index];
      if (zone.region == Region.naranja) {
        expect(
          find.textContaining(
            'Naranja ${zone.valorMinimo}-${zone.valorMaximo}',
          ),
          findsOneWidget,
        );
      }
    }
    expect(find.textContaining('Puntos: '), findsWidgets);
    expect(find.text('Reglas por color y zona'), findsNothing);
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

    expect(find.text('Puntos de las zonas'), findsNothing);
    expect(find.byKey(const ValueKey('placement-guide')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('drawer-tab-instructions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drawer-backdrop')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('instructions-drawer-list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.text('Puntos de las zonas'), findsOneWidget);
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
    final upperOrangeLabel = find.textContaining(
      'Zona ${upperOrangeIndex + 1} · Naranja 4-6',
    );
    expect(upperOrangeLabel, findsOneWidget);
    expect(find.textContaining('Puntos: '), findsWidgets);
    expect(find.text('La zona acepta números del 4 al 6.'), findsNothing);

    final lowerOrangeIndex = board.zonas.indexWhere(
      (zone) => zone.region == Region.naranja && zone.valorMinimo == 1,
    );
    final lowerOrangeLabel = find.textContaining(
      'Zona ${lowerOrangeIndex + 1} · Naranja 1-3',
    );
    await tester.ensureVisible(lowerOrangeLabel);
    expect(lowerOrangeLabel, findsOneWidget);
    final zoneColor = find.byKey(
      ValueKey('zone-color-${upperOrangeIndex + 1}'),
    );
    await tester.ensureVisible(zoneColor);
    await tester.tap(zoneColor);
    await tester.pumpAndSettle();
    final [row, column] = board.zonas[upperOrangeIndex].posiciones.first;
    final highlightedCellFinder = find.descendant(
      of: find.byKey(ValueKey('casilla-juego-$row-$column')),
      matching: find.byType(AnimatedContainer),
    );
    final highlightedCell = tester.widget<AnimatedContainer>(
      highlightedCellFinder,
    );
    expect(
      (highlightedCell.decoration! as BoxDecoration).border!.top.color,
      Colors.deepPurple,
    );
    expect(find.textContaining('Zona '), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('drawer-tab-instructions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drawer-backdrop')), findsNothing);
    expect(find.text('Puntos de las zonas'), findsNothing);
    expect(
      (tester.widget<AnimatedContainer>(highlightedCellFinder).decoration!
              as BoxDecoration)
          .border!
          .top
          .color,
      Colors.deepPurple,
    );
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

  testWidgets('conserva zonas y puntaje durante una desconexión en partida', (
    tester,
  ) async {
    _configurarSuperficie(tester);
    final service =
        _FakeMultiplayerService(
            room: MultiplayerRoom(
              code: 'ROOM01',
              hostId: 'player-top',
              capacity: 2,
              boardId: 1,
              targetPoints: 30,
              status: 'playing',
              players: const [
                MultiplayerPlayer(
                  id: 'player-top',
                  username: 'Ana',
                  ready: true,
                  connected: false,
                  score: 24,
                  finished: false,
                  setupComplete: true,
                ),
                MultiplayerPlayer(
                  id: 'player-second',
                  username: 'Luis',
                  ready: true,
                  connected: true,
                  score: 12,
                  finished: false,
                  setupComplete: true,
                ),
              ],
            ),
            game: const MultiplayerGameState(
              turn: 4,
              dice: [2, 5],
              phase: 'playing',
              setupCompletePlayerIds: {'player-top', 'player-second'},
              completedPlayerIds: {},
              zoneClaims: {
                0: [
                  {'playerId': 'player-top', 'username': 'Ana', 'points': 8},
                ],
              },
              winnerId: null,
            ),
          )
          ..connected = false
          ..playAllowed = false
          ..ownScore = 24;

    await tester.pumpWidget(
      MaterialApp(
        home: JuegoScreen(tablero: crearTablero(1), multiplayer: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('🏆 24 pts'), findsOneWidget);
    expect(find.text('Partida finalizada'), findsNothing);
    expect(
      find.text(
        'Sin conexión. Reconectando; tus puntos y turnos se conservan.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('drawer-tab-players')));
    await tester.pumpAndSettle();
    expect(find.text('Zona 1 · Amarillo'), findsOneWidget);
    expect(find.text('+8 pts'), findsOneWidget);
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

    expect(
      find.text('Ana capturó la Zona 1 (Amarillo) y obtuvo +8 pts.'),
      findsOneWidget,
    );
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

  testWidgets(
    'muestra el bono del +20% al ganar a un superior y 0 pts perdidos al caer ante un superior en Ranked',
    (tester) async {
      _configurarSuperficie(tester);
      // Ana (100 pts, Principiante) vence con 25 pts a Luis (300 pts, Nuevo héroe)
      final serviceVictoriaSuperior = _FakeMultiplayerService(
        room: const MultiplayerRoom(
          code: 'RANK01',
          hostId: 'player-ana',
          capacity: 2,
          boardId: 1,
          targetPoints: 26,
          status: 'finished',
          ranked: true,
          players: [
            MultiplayerPlayer(
              id: 'player-ana',
              username: 'Ana',
              ready: true,
              connected: true,
              score: 25,
              finished: true,
              setupComplete: true,
              rankedPoints: 100,
            ),
            MultiplayerPlayer(
              id: 'player-luis',
              username: 'Luis',
              ready: true,
              connected: true,
              score: 18,
              finished: true,
              setupComplete: true,
              rankedPoints: 300,
            ),
          ],
        ),
        game: const MultiplayerGameState(
          turn: 10,
          dice: [3, 4],
          phase: 'finished',
          setupCompletePlayerIds: {'player-ana', 'player-luis'},
          completedPlayerIds: {'player-ana', 'player-luis'},
          zoneClaims: {},
          winnerId: 'player-ana',
        ),
      )..playerId = 'player-ana';

      await tester.pumpWidget(
        MaterialApp(
          home: JuegoScreen(
            tablero: crearTablero(1),
            multiplayer: serviceVictoriaSuperior,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Modo Clasificatoria (Ranked)'), findsOneWidget);
      expect(find.text('Ganador: Ana'), findsOneWidget);
      // 25 pts + 20% = +30 pts -> 100 + 30 = 130 pts (Principiante)
      expect(
        find.text('Ranked: +30 pts → Principiante (130 pts)'),
        findsOneWidget,
      );
      // Luis tenía 300 pts y perdió contra Ana (100 pts, inferior): pierde diferencia (25 - 18 = 7) -> 293 pts
      expect(
        find.text('Ranked: -7 pts → Principiante (293 pts)'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'no descuenta puntos en el resultado final cuando pierdes contra un jugador destacado por encima de ti',
    (tester) async {
      _configurarSuperficie(tester);
      // Luis (300 pts, Nuevo héroe) vence con 26 pts a Ana (100 pts, Principiante)
      final serviceDerrotaContraSuperior = _FakeMultiplayerService(
        room: const MultiplayerRoom(
          code: 'RANK02',
          hostId: 'player-ana',
          capacity: 2,
          boardId: 1,
          targetPoints: 26,
          status: 'finished',
          ranked: true,
          players: [
            MultiplayerPlayer(
              id: 'player-luis',
              username: 'Luis',
              ready: true,
              connected: true,
              score: 26,
              finished: true,
              setupComplete: true,
              rankedPoints: 300,
            ),
            MultiplayerPlayer(
              id: 'player-ana',
              username: 'Ana',
              ready: true,
              connected: true,
              score: 18,
              finished: true,
              setupComplete: true,
              rankedPoints: 100,
            ),
          ],
        ),
        game: const MultiplayerGameState(
          turn: 10,
          dice: [2, 6],
          phase: 'finished',
          setupCompletePlayerIds: {'player-ana', 'player-luis'},
          completedPlayerIds: {'player-ana', 'player-luis'},
          zoneClaims: {},
          winnerId: 'player-luis',
        ),
      )..playerId = 'player-ana';

      await tester.pumpWidget(
        MaterialApp(
          home: JuegoScreen(
            tablero: crearTablero(1),
            multiplayer: serviceDerrotaContraSuperior,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Modo Clasificatoria (Ranked)'), findsOneWidget);
      expect(find.text('Ganador: Luis'), findsOneWidget);
      // Ana perdió contra un jugador destacado por encima de ella (300 > 100): 0 pts perdidos
      expect(
        find.text('Ranked: 0 pts → Principiante (100 pts)'),
        findsOneWidget,
      );
      // Luis ganó contra alguien de menor rango: suma sus 26 pts normales -> 326 pts
      expect(
        find.text('Ranked: +26 pts → Nuevo héroe (326 pts)'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'al salir de una partida en ejecución o en configuración inicial libera la sala para poder crear otra sin error',
    (tester) async {
      _configurarSuperficie(tester);
      final runningGameService = _FakeMultiplayerService(
        room: const MultiplayerRoom(
          code: 'PLAY01',
          hostId: 'player-top',
          capacity: 2,
          boardId: 1,
          targetPoints: 26,
          status: 'playing',
          ranked: true,
          players: [
            MultiplayerPlayer(
              id: 'player-top',
              username: 'Ana',
              ready: true,
              connected: true,
              score: 10,
              finished: false,
              setupComplete: true,
              rankedPoints: 100,
            ),
            MultiplayerPlayer(
              id: 'player-second',
              username: 'Luis',
              ready: true,
              connected: true,
              score: 8,
              finished: false,
              setupComplete: true,
              rankedPoints: 300,
            ),
          ],
        ),
        game: const MultiplayerGameState(
          turn: 2,
          dice: [1, 4],
          phase: 'playing',
          setupCompletePlayerIds: {'player-top', 'player-second'},
          completedPlayerIds: {},
          zoneClaims: {},
          winnerId: null,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => JuegoScreen(
                        tablero: crearTablero(1),
                        multiplayer: runningGameService,
                      ),
                    ),
                  );
                },
                child: const Text('Entrar a partida'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Entrar a partida'));
      await tester.pumpAndSettle();

      // El jugador pulsa el botón de salir durante la partida en ejecución
      await tester.tap(find.byTooltip('Salir de la partida'));
      await tester.pumpAndSettle();

      expect(find.text('¿Salir de la partida?'), findsOneWidget);
      await tester.tap(find.text('Salir de todos modos'));
      await tester.pumpAndSettle();

      expect(runningGameService.leaveCalls, 1);
      expect(runningGameService.disposeCalls, 1);
      expect(runningGameService.room, isNull);
      expect(find.text('Entrar a partida'), findsOneWidget);
    },
  );

  testWidgets(
    'reproduce música en bucle sin reiniciarse entre turnos, efectos de sonido y botón de engranaje',
    (tester) async {
      _configurarSuperficie(tester);
      final audio = AudioService.instance;
      audio.reiniciarEstadoParaPruebas();

      // En partida casual inicia The Classroom.mp3 y no reinicia el ciclo al avanzar de turno
      await tester.pumpWidget(const MaterialApp(home: InicioScreen()));
      expect(find.byKey(const ValueKey('audio-settings-button')), findsOneWidget);

      await _elegirTablero(tester, 1);
      expect(audio.ultimoSonidoReproducido, AudioAssets.sonidoSelect);

      // Coloca un número y luego muévelo a otra casilla para disparar la explosión
      await _colocarNumero(tester, 1);
      expect(
        audio.historialSonidos,
        contains(AudioAssets.sonidoColocarNumero),
      );

      await tester.tap(find.text('+').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '1'));
      await tester.pumpAndSettle();
      expect(audio.ultimoSonidoReproducido, AudioAssets.sonidoExplosion);

      for (var numero = 2; numero <= 6; numero++) {
        await _colocarNumero(tester, numero);
      }

      await tester.tap(find.text('¡LISTO! AVANZAR'));
      await tester.pumpAndSettle();

      expect(audio.pistaMusicaActual, AudioAssets.musicaPartidaCasual);
      final iniciosMusicaAlEmpezar = audio.conteoIniciosMusica;
      expect(iniciosMusicaAlEmpezar, 1);
      expect(audio.historialSonidos, contains(AudioAssets.sonidoDado));

      // Colocar y deshacer un número reproduce C_numero.mp3 y D_numero.mp3
      await tester.tap(_primeraCasillaValida());
      await tester.pumpAndSettle();
      expect(audio.ultimoSonidoReproducido, AudioAssets.sonidoColocarNumero);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(audio.ultimoSonidoReproducido, AudioAssets.sonidoDeshacerNumero);

      // Avanzar turno NO reinicia la música de fondo
      await _jugarPrimerMovimientoDisponible(tester);
      expect(audio.pistaMusicaActual, AudioAssets.musicaPartidaCasual);
      expect(audio.conteoIniciosMusica, iniciosMusicaAlEmpezar);

      // El botón de engranaje está presente y permite desactivar y activar música y sonidos por separado
      await tester.tap(find.byKey(const ValueKey('audio-settings-button')));
      await tester.pumpAndSettle();
      expect(find.text('Configuración de audio'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('toggle-musica-switch')));
      await tester.pumpAndSettle();
      expect(audio.musicaActiva, isFalse);
      expect(audio.pistaMusicaActual, isNull);

      await tester.tap(find.byKey(const ValueKey('toggle-sonidos-switch')));
      await tester.pumpAndSettle();
      expect(audio.sonidosActivos, isFalse);

      await tester.tap(find.byKey(const ValueKey('toggle-musica-switch')));
      await tester.pumpAndSettle();
      expect(audio.musicaActiva, isTrue);
      expect(audio.pistaMusicaActual, AudioAssets.musicaPartidaCasual);

      await tester.tap(find.byKey(const ValueKey('toggle-sonidos-switch')));
      await tester.pumpAndSettle();
      expect(audio.sonidosActivos, isTrue);

      await tester.tap(
        find.byKey(const ValueKey('close-audio-settings-button')),
      );
      await tester.pumpAndSettle();
      expect(audio.ultimoSonidoReproducido, AudioAssets.sonidoBack);
    },
  );

  testWidgets(
    'usa Final Destination.mp3 en clasificatoria y distingue sonido de zona propia vs otro jugador',
    (tester) async {
      _configurarSuperficie(tester);
      final audio = AudioService.instance;
      audio.reiniciarEstadoParaPruebas();

      final service = _FakeMultiplayerService(
        room: const MultiplayerRoom(
          code: 'RANK55',
          hostId: 'player-top',
          capacity: 2,
          boardId: 1,
          targetPoints: 26,
          status: 'playing',
          ranked: true,
          players: [
            MultiplayerPlayer(
              id: 'player-top',
              username: 'Ana',
              ready: true,
              connected: true,
              score: 0,
              finished: false,
              setupComplete: true,
              rankedPoints: 100,
            ),
            MultiplayerPlayer(
              id: 'player-rival',
              username: 'Luis',
              ready: true,
              connected: true,
              score: 0,
              finished: false,
              setupComplete: true,
              rankedPoints: 300,
            ),
          ],
        ),
        game: const MultiplayerGameState(
          turn: 1,
          dice: [2, 5],
          phase: 'playing',
          setupCompletePlayerIds: {'player-top', 'player-rival'},
          completedPlayerIds: {},
          zoneClaims: {},
          winnerId: null,
        ),
      )..playerId = 'player-top';

      await tester.pumpWidget(
        MaterialApp(
          home: JuegoScreen(tablero: crearTablero(1), multiplayer: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(audio.pistaMusicaActual, AudioAssets.musicaPartidaClasificatoria);
      expect(audio.conteoIniciosMusica, 1);

      // Cuando tú tomas una zona suena Zona.wav
      service.game = const MultiplayerGameState(
        turn: 1,
        dice: [2, 5],
        phase: 'playing',
        setupCompletePlayerIds: {'player-top', 'player-rival'},
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
      expect(audio.ultimoSonidoReproducido, AudioAssets.sonidoZonaPropia);

      // Cuando alguien más captura una zona suena Gato_riendose_Meme.wav y el cambio de turno no reinicia la música
      service.game = const MultiplayerGameState(
        turn: 2,
        dice: [3, 4],
        phase: 'playing',
        setupCompletePlayerIds: {'player-top', 'player-rival'},
        completedPlayerIds: {},
        zoneClaims: {
          0: [
            {'playerId': 'player-top', 'username': 'Ana', 'points': 8},
          ],
          1: [
            {'playerId': 'player-rival', 'username': 'Luis', 'points': 4},
          ],
        },
        winnerId: null,
      );
      service.notifyListeners();
      await tester.pumpAndSettle();
      expect(
        audio.historialSonidos,
        contains(AudioAssets.sonidoZonaOtroJugador),
      );
      expect(audio.conteoIniciosMusica, 1);

      // Al terminar la partida suena End_game.mp3
      service.room = const MultiplayerRoom(
        code: 'RANK55',
        hostId: 'player-top',
        capacity: 2,
        boardId: 1,
        targetPoints: 26,
        status: 'finished',
        ranked: true,
        players: [
          MultiplayerPlayer(
            id: 'player-top',
            username: 'Ana',
            ready: true,
            connected: true,
            score: 26,
            finished: true,
            setupComplete: true,
            rankedPoints: 100,
          ),
          MultiplayerPlayer(
            id: 'player-rival',
            username: 'Luis',
            ready: true,
            connected: true,
            score: 14,
            finished: true,
            setupComplete: true,
            rankedPoints: 300,
          ),
        ],
      );
      service.game = const MultiplayerGameState(
        turn: 2,
        dice: [3, 4],
        phase: 'finished',
        setupCompletePlayerIds: {'player-top', 'player-rival'},
        completedPlayerIds: {'player-top', 'player-rival'},
        zoneClaims: {},
        winnerId: 'player-top',
      );
      service.notifyListeners();
      await tester.pumpAndSettle();
      expect(audio.ultimoSonidoReproducido, AudioAssets.sonidoFinPartida);
    },
  );

  group('Modo Contra reloj (temporizador)', () {
    Tablero crearTableroConIniciales() {
      final board = crearTablero(1);
      final initialPositions = obtenerPosicionesInicialesTablero(1);
      for (var i = 0; i < initialPositions.length; i++) {
        final pos = initialPositions[i];
        board.celdas[pos[0]][pos[1]] = i + 1;
      }
      return board;
    }

    List<int> dadosConMovimiento(Tablero board) {
      for (var d1 = 1; d1 <= 6; d1++) {
        for (var d2 = 1; d2 <= 6; d2++) {
          if (obtenerPosicionesValidas(board, d1, d2).isNotEmpty ||
              obtenerPosicionesValidas(board, d2, d1).isNotEmpty) {
            return [d1, d2];
          }
        }
      }
      return [1, 2];
    }

    testWidgets(
      'cuando ya jugaste y esperas a los demás y se acaba el tiempo, no pierdes el número colocado',
      (tester) async {
        _configurarSuperficie(tester);
        final board = crearTableroConIniciales();
        final dice = dadosConMovimiento(board);
        final service = _FakeMultiplayerService(
          room: const MultiplayerRoom(
            code: 'TT0001',
            hostId: 'player-top',
            capacity: 2,
            boardId: 1,
            targetPoints: 26,
            status: 'playing',
            timeTrial: true,
            players: [
              MultiplayerPlayer(
                id: 'player-top',
                username: 'Ana',
                ready: true,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: true,
              ),
              MultiplayerPlayer(
                id: 'player-second',
                username: 'Luis',
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
            setupCompletePlayerIds: const {'player-top', 'player-second'},
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
        await tester.pump();

        expect(find.byKey(const ValueKey('turn-timer-badge')), findsOneWidget);
        expect(find.text('⏱ 02:00'), findsOneWidget);

        // Coloca un número y confirma el turno
        await tester.tap(_primeraCasillaValida());
        await tester.pump();
        final celdasAntesDeConfirmar = board.celdas
            .expand((row) => row)
            .where((v) => v != 0)
            .length;
        expect(celdasAntesDeConfirmar, 7);

        await tester.tap(find.text('Avanzar Turno'));
        await tester.pump();
        expect(find.text('ESPERANDO A LOS JUGADORES'), findsOneWidget);
        expect(service.completeTurnCalls, 1);

        // Se acaba el tiempo de 2 minutos mientras espera a los demás
        await tester.pump(const Duration(minutes: 2));
        expect(find.text('⏱ 00:00'), findsOneWidget);

        // El número colocado sigue intacto y no se perdió ni se reenvió vacío
        final celdasDespuesDeTiempo = board.celdas
            .expand((row) => row)
            .where((v) => v != 0)
            .length;
        expect(celdasDespuesDeTiempo, 7);
        expect(service.completeTurnCalls, 1);
      },
    );

    testWidgets(
      'cuando colocas un número después del ancla y no presionas confirmar jugada antes de acabar el tiempo, aún se acepta',
      (tester) async {
        _configurarSuperficie(tester);
        final board = crearTableroConIniciales();
        final dice = dadosConMovimiento(board);
        final service = _FakeMultiplayerService(
          room: const MultiplayerRoom(
            code: 'TT0002',
            hostId: 'player-top',
            capacity: 2,
            boardId: 1,
            targetPoints: 26,
            status: 'playing',
            timeTrial: true,
            players: [
              MultiplayerPlayer(
                id: 'player-top',
                username: 'Ana',
                ready: true,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: true,
              ),
              MultiplayerPlayer(
                id: 'player-second',
                username: 'Luis',
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
            setupCompletePlayerIds: const {'player-top', 'player-second'},
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
        await tester.pump();

        // Coloca el número después del ancla pero NO presiona "Avanzar Turno"
        await tester.tap(_primeraCasillaValida());
        await tester.pump();
        expect(find.text('Avanzar Turno'), findsOneWidget);
        expect(service.completeTurnCalls, 0);

        // Pasan los 2 minutos del turno
        await tester.pump(const Duration(minutes: 2));

        // Debe aceptar y enviar la jugada con el 7mo número colocado
        expect(service.completeTurnCalls, 1);
        expect(
          service.lastSubmittedBoard!.where((v) => v != 0).length,
          7,
        );
        expect(
          board.celdas.expand((row) => row).where((v) => v != 0).length,
          7,
        );
      },
    );

    testWidgets(
      'el tiempo sigue avanzando mientras ves los jugadores conectados o las instrucciones',
      (tester) async {
        _configurarSuperficie(tester);
        final board = crearTableroConIniciales();
        final dice = dadosConMovimiento(board);
        final service = _FakeMultiplayerService(
          room: const MultiplayerRoom(
            code: 'TT0003',
            hostId: 'player-top',
            capacity: 2,
            boardId: 1,
            targetPoints: 26,
            status: 'playing',
            timeTrial: true,
            players: [
              MultiplayerPlayer(
                id: 'player-top',
                username: 'Ana',
                ready: true,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: true,
              ),
              MultiplayerPlayer(
                id: 'player-second',
                username: 'Luis',
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
            setupCompletePlayerIds: const {'player-top', 'player-second'},
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
        await tester.pump();
        expect(find.text('⏱ 02:00'), findsOneWidget);

        // Abre el panel de jugadores conectados y deja pasar 10 segundos
        await tester.tap(find.byKey(const ValueKey('drawer-tab-players')));
        await tester.pump(const Duration(seconds: 10));
        expect(find.text('⏱ 01:50'), findsOneWidget);

        // Cierra jugadores y abre instrucciones, deja pasar 15 segundos más
        await tester.tap(find.byKey(const ValueKey('drawer-tab-players')));
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.byKey(const ValueKey('drawer-tab-instructions')));
        await tester.pump(const Duration(seconds: 15));
        expect(find.text('⏱ 01:34'), findsOneWidget);
      },
    );

    testWidgets(
      'al terminar la partida desaparece el temporizador',
      (tester) async {
        _configurarSuperficie(tester);
        final board = crearTableroConIniciales();
        final service = _FakeMultiplayerService(
          room: const MultiplayerRoom(
            code: 'TT0004',
            hostId: 'player-top',
            capacity: 2,
            boardId: 1,
            targetPoints: 26,
            status: 'playing',
            timeTrial: true,
            players: [
              MultiplayerPlayer(
                id: 'player-top',
                username: 'Ana',
                ready: true,
                connected: true,
                score: 20,
                finished: false,
                setupComplete: true,
              ),
              MultiplayerPlayer(
                id: 'player-second',
                username: 'Luis',
                ready: true,
                connected: true,
                score: 12,
                finished: false,
                setupComplete: true,
              ),
            ],
          ),
          game: const MultiplayerGameState(
            turn: 5,
            dice: [2, 4],
            phase: 'playing',
            setupCompletePlayerIds: {'player-top', 'player-second'},
            completedPlayerIds: {},
            zoneClaims: {},
            winnerId: null,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: JuegoScreen(tablero: board, multiplayer: service),
          ),
        );
        await tester.pump();
        expect(find.byKey(const ValueKey('turn-timer-badge')), findsOneWidget);

        // Finaliza la partida
        service.room = const MultiplayerRoom(
          code: 'TT0004',
          hostId: 'player-top',
          capacity: 2,
          boardId: 1,
          targetPoints: 26,
          status: 'finished',
          timeTrial: true,
          players: [
            MultiplayerPlayer(
              id: 'player-top',
              username: 'Ana',
              ready: true,
              connected: true,
              score: 26,
              finished: true,
              setupComplete: true,
            ),
            MultiplayerPlayer(
              id: 'player-second',
              username: 'Luis',
              ready: true,
              connected: true,
              score: 12,
              finished: true,
              setupComplete: true,
            ),
          ],
        );
        service.game = const MultiplayerGameState(
          turn: 5,
          dice: [2, 4],
          phase: 'finished',
          setupCompletePlayerIds: {'player-top', 'player-second'},
          completedPlayerIds: {'player-top', 'player-second'},
          zoneClaims: {},
          winnerId: 'player-top',
        );
        service.notifyListeners();
        await tester.pump();

        expect(find.byKey(const ValueKey('turn-timer-badge')), findsNothing);
      },
    );

    testWidgets(
      'muestra el temporizador de 5 minutos al elegir los números iniciales en modo Contra reloj',
      (tester) async {
        _configurarSuperficie(tester);
        final service = _FakeMultiplayerService(
          room: const MultiplayerRoom(
            code: 'TT0005',
            hostId: 'player-top',
            capacity: 2,
            boardId: 1,
            targetPoints: 26,
            status: 'playing',
            timeTrial: true,
            players: [
              MultiplayerPlayer(
                id: 'player-top',
                username: 'Ana',
                ready: true,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: false,
              ),
              MultiplayerPlayer(
                id: 'player-second',
                username: 'Luis',
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
            dice: [1, 3],
            phase: 'setup',
            setupCompletePlayerIds: {},
            completedPlayerIds: {},
            zoneClaims: {},
            winnerId: null,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: InicioScreen(tableroInicial: 1, multiplayer: service),
          ),
        );
        await tester.pump();

        expect(find.byKey(const ValueKey('setup-timer-badge')), findsOneWidget);
        expect(find.text('⏱ 05:00'), findsOneWidget);

        await tester.pump(const Duration(seconds: 5));
        expect(find.text('⏱ 04:55'), findsOneWidget);
      },
    );

    testWidgets(
      'cuando no está activo el modo Contra reloj no se muestra el cronómetro en inicio ni en partida',
      (tester) async {
        _configurarSuperficie(tester);
        final serviceSinContraReloj = _FakeMultiplayerService(
          room: const MultiplayerRoom(
            code: 'NORM01',
            hostId: 'player-top',
            capacity: 2,
            boardId: 1,
            targetPoints: 26,
            status: 'playing',
            timeTrial: false,
            players: [
              MultiplayerPlayer(
                id: 'player-top',
                username: 'Ana',
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
            dice: [1, 2],
            phase: 'setup',
            setupCompletePlayerIds: {},
            completedPlayerIds: {},
            zoneClaims: {},
            winnerId: null,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: InicioScreen(
              tableroInicial: 1,
              multiplayer: serviceSinContraReloj,
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const ValueKey('setup-timer-badge')), findsNothing);

        await tester.pumpWidget(
          MaterialApp(
            home: JuegoScreen(
              tablero: crearTableroConIniciales(),
              multiplayer: serviceSinContraReloj,
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const ValueKey('turn-timer-badge')), findsNothing);
      },
    );
  });
}
