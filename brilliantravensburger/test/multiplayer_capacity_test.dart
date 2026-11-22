import 'package:brilliantravensburger/lobby_screen.dart';
import 'package:brilliantravensburger/multiplayer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLobbyMultiplayerService extends ChangeNotifier
    implements MultiplayerService {
  _FakeLobbyMultiplayerService({this.initialRankedPoints = 100});

  final int initialRankedPoints;
  final String username = 'Anfitrión';
  int createCalls = 0;
  int joinCalls = 0;
  int leaveCalls = 0;
  bool lastCreatedRanked = false;

  @override
  MultiplayerRoom? room;

  @override
  MultiplayerGameState? game;

  @override
  String? playerId = 'player-host';

  @override
  String? lastError;

  @override
  bool get isConnected => true;

  @override
  bool get canPlay => true;

  @override
  int get myScore => 0;

  @override
  bool get myTurnIsComplete => false;

  @override
  bool get mySetupIsComplete => false;

  @override
  bool get myBoardIsComplete => false;

  @override
  List<int>? get myBoard => null;

  @override
  Future<void> createRoom({
    required int capacity,
    required int boardId,
    required List<List<int>> zonePointValues,
    bool ranked = false,
  }) async {
    createCalls++;
    lastCreatedRanked = ranked;
    room = MultiplayerRoom(
      code: 'ROOM0$createCalls',
      hostId: 'player-host',
      capacity: capacity,
      boardId: boardId,
      targetPoints: 26,
      status: 'waiting',
      ranked: ranked,
      players: [
        MultiplayerPlayer(
          id: 'player-host',
          username: username,
          ready: false,
          connected: true,
          score: 0,
          finished: false,
          setupComplete: false,
          rankedPoints: initialRankedPoints,
        ),
      ],
    );
    notifyListeners();
  }

  @override
  Future<void> joinRoom(String code) async {
    joinCalls++;
    room = MultiplayerRoom(
      code: code.trim().toUpperCase(),
      hostId: 'player-host',
      capacity: 2,
      boardId: 1,
      targetPoints: 26,
      status: 'waiting',
      ranked: true,
      players: [
        const MultiplayerPlayer(
          id: 'player-host',
          username: 'Anfitrión',
          ready: true,
          connected: true,
          score: 0,
          finished: false,
          setupComplete: false,
          rankedPoints: 300,
        ),
        MultiplayerPlayer(
          id: 'player-guest',
          username: username,
          ready: false,
          connected: true,
          score: 0,
          finished: false,
          setupComplete: false,
          rankedPoints: initialRankedPoints,
        ),
      ],
    );
    playerId = 'player-guest';
    notifyListeners();
  }

  @override
  Future<void> leaveRoom() async {
    leaveCalls++;
    room = null;
    game = null;
    notifyListeners();
  }

  @override
  Future<void> setReady(bool ready) async {
    final currentRoom = room;
    if (currentRoom == null) return;
    room = MultiplayerRoom(
      code: currentRoom.code,
      hostId: currentRoom.hostId,
      capacity: currentRoom.capacity,
      boardId: currentRoom.boardId,
      targetPoints: currentRoom.targetPoints,
      status: currentRoom.status,
      ranked: currentRoom.ranked,
      players: [
        for (final player in currentRoom.players)
          if (player.id == playerId)
            MultiplayerPlayer(
              id: player.id,
              username: player.username,
              ready: ready,
              connected: player.connected,
              score: player.score,
              finished: player.finished,
              setupComplete: player.setupComplete,
              rankedPoints: player.rankedPoints,
            )
          else
            player,
      ],
    );
    notifyListeners();
  }

  @override
  Future<void> setBoard({
    required int boardId,
    required List<List<int>> zonePointValues,
  }) async {}

  @override
  Future<void> completeTurn({
    required List<int> board,
    required List<int> completedZones,
    required bool finished,
  }) async {}

  @override
  Future<void> completeInitialSetup({required List<int> board}) async {}

  @override
  Future<void> retryRoomRestore() async {}
}

void main() {
  group('Modelos de datos multijugador', () {
    test(
      'convierte campos opcionales del jugador a sus valores por defecto',
      () {
        final player = MultiplayerPlayer.fromJson({
          'id': 'player-1',
          'score': 12.9,
        });

        expect(player.id, 'player-1');
        expect(player.username, 'Jugador');
        expect(player.ready, isFalse);
        expect(player.connected, isTrue);
        expect(player.score, 12);
        expect(player.finished, isFalse);
      },
    );

    test('conserva estado de conexión, puntuación y finalización', () {
      final player = MultiplayerPlayer.fromJson({
        'id': 'player-2',
        'username': 'Ana',
        'ready': true,
        'connected': false,
        'score': 27,
        'finished': true,
      });

      expect(player.username, 'Ana');
      expect(player.ready, isTrue);
      expect(player.connected, isFalse);
      expect(player.score, 27);
      expect(player.finished, isTrue);
      expect(player.setupComplete, isFalse);
    });

    test('usa valores iniciales cuando el estado de juego está vacío', () {
      final game = MultiplayerGameState.fromJson({});

      expect(game.turn, 1);
      expect(game.dice, [1, 1]);
      expect(game.completedPlayerIds, isEmpty);
      expect(game.zoneClaims, isEmpty);
      expect(game.winnerId, isNull);
    });

    test('lee ganador, turnos completados y capturas de varias zonas', () {
      final game = MultiplayerGameState.fromJson({
        'turn': 8,
        'dice': [3, 6],
        'phase': 'setup',
        'setupCompletePlayerIds': ['player-1', 'player-2'],
        'completedPlayerIds': ['player-1', 'player-2', 'player-1'],
        'zoneClaims': {
          '1': [
            {'playerId': 'player-1', 'points': 10},
          ],
          '4': [
            {'playerId': 'player-2', 'points': 7},
            {'playerId': 'player-1', 'points': 5},
          ],
        },
        'winnerId': 'player-1',
      });

      expect(game.turn, 8);
      expect(game.dice, [3, 6]);
      expect(game.phase, 'setup');
      expect(game.setupCompletePlayerIds, {'player-1', 'player-2'});
      expect(game.completedPlayerIds, {'player-1', 'player-2'});
      expect(game.zoneClaims.keys, containsAll([1, 4]));
      expect(game.zoneClaims[1], [
        {'playerId': 'player-1', 'points': 10},
      ]);
      expect(game.zoneClaims[4], hasLength(2));
      expect(game.winnerId, 'player-1');
    });

    test('conserva los tableros compartidos al recibir el estado final', () {
      final game = MultiplayerGameState.fromJson({
        'playerBoards': {
          'player-1': List<int>.filled(49, 2),
          'player-2': List<int>.filled(49, 5),
        },
      });

      expect(game.playerBoards['player-1'], hasLength(49));
      expect(game.playerBoards['player-1']!.first, 2);
      expect(game.playerBoards['player-2']!.first, 5);
    });

    test('conserva a los jugadores desconectados en una sala de espera', () {
      final room = MultiplayerRoom.fromJson({
        'code': 'ROOM01',
        'hostId': 'player-host',
        'capacity': 2,
        'boardId': 1,
        'targetPoints': 20,
        'status': 'waiting',
        'players': [
          {
            'id': 'player-host',
            'username': 'Anfitrión',
            'ready': true,
            'connected': false,
          },
          {'id': 'player-guest', 'username': 'Invitado', 'connected': true},
        ],
      });

      expect(room.status, 'waiting');
      expect(room.players, hasLength(2));
      expect(room.players.first.connected, isFalse);
      expect(room.players.first.ready, isTrue);
    });

    test(
      'mantiene los puntos y las capturas tras desconectarse en una partida activa',
      () {
        final room = MultiplayerRoom.fromJson({
          'code': 'ROOM01',
          'hostId': 'player-host',
          'capacity': 2,
          'boardId': 1,
          'targetPoints': 20,
          'status': 'playing',
          'players': [
            {
              'id': 'player-host',
              'username': 'Anfitrión',
              'connected': false,
              'score': 24,
              'finished': false,
            },
            {
              'id': 'player-guest',
              'username': 'Invitado',
              'connected': true,
              'score': 12,
              'finished': false,
            },
          ],
        });
        final game = MultiplayerGameState.fromJson({
          'phase': 'playing',
          'zoneClaims': {
            '0': [
              {'playerId': 'player-host', 'username': 'Anfitrión', 'points': 8},
            ],
          },
          'winnerId': null,
        });

        expect(room.status, 'playing');
        expect(room.players.first.connected, isFalse);
        expect(room.players.first.score, greaterThan(room.players.last.score));
        expect(game.zoneClaims[0]?.single['points'], 8);
        expect(game.winnerId, isNull);
      },
    );
  });

  group('Partidas multijugador por cantidad de jugadores', () {
    test('muestra si todos confirmaron sus números iniciales', () {
      MultiplayerRoom roomWithOneReady = MultiplayerRoom.fromJson({
        'code': 'ROOM01',
        'hostId': 'player-1',
        'capacity': 2,
        'boardId': 1,
        'targetPoints': 26,
        'status': 'playing',
        'players': [
          {
            'id': 'player-1',
            'username': 'Ana',
            'connected': true,
            'setupComplete': true,
          },
          {
            'id': 'player-2',
            'username': 'Luis',
            'connected': false,
            'setupComplete': false,
          },
        ],
      });

      expect(roomWithOneReady.setupCompleteCount, 1);
      expect(roomWithOneReady.allPlayersSetupComplete, isFalse);
      expect(roomWithOneReady.players.last.connected, isFalse);

      final roomWithEveryoneReady = MultiplayerRoom.fromJson({
        'code': 'ROOM01',
        'hostId': 'player-1',
        'capacity': 2,
        'boardId': 1,
        'targetPoints': 26,
        'status': 'playing',
        'players': [
          {
            'id': 'player-1',
            'username': 'Ana',
            'connected': true,
            'setupComplete': true,
          },
          {
            'id': 'player-2',
            'username': 'Luis',
            'connected': true,
            'setupComplete': true,
          },
        ],
      });

      expect(roomWithEveryoneReady.setupCompleteCount, 2);
      expect(roomWithEveryoneReady.allPlayersSetupComplete, isTrue);
    });

    for (final capacity in [2, 3, 4, 5, 6]) {
      test('carga la sala y el estado de juego con $capacity jugadores', () {
        final players = List.generate(
          capacity,
          (index) => {
            'id': 'player-$index',
            'username': 'Jugador $index',
            'ready': true,
            'connected': true,
            'score': index * 2,
            'finished': false,
          },
        );
        final room = MultiplayerRoom.fromJson({
          'code': 'ROOM01',
          'hostId': 'player-0',
          'capacity': capacity,
          'boardId': 1,
          'targetPoints': 30,
          'status': 'playing',
          'players': players,
        });
        final game = MultiplayerGameState.fromJson({
          'turn': 3,
          'dice': [2, 5],
          'completedPlayerIds': players.map((player) => player['id']).toList(),
          'zoneClaims': {
            '1': [
              {'playerId': 'player-0', 'score': 8},
            ],
          },
          'winnerId': null,
        });

        expect(room.capacity, capacity);
        expect(room.players, hasLength(capacity));
        expect(
          room.players.map((player) => player.id).toSet(),
          hasLength(capacity),
        );
        expect(room.players.every((player) => player.ready), isTrue);
        expect(room.players.every((player) => player.connected), isTrue);
        expect(game.turn, 3);
        expect(game.dice, [2, 5]);
        expect(game.completedPlayerIds, hasLength(capacity));
        expect(game.zoneClaims[1], [
          {'playerId': 'player-0', 'score': 8},
        ]);
      });
    }

    testWidgets('permite configurar salas de 2 a 6 jugadores', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LobbyScreen(token: 'token', username: 'Anfitrión'),
        ),
      );

      final capacityDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<int> &&
            widget.decoration.labelText == 'Cantidad de jugadores',
      );
      expect(
        tester
            .widget<DropdownButtonFormField<int>>(capacityDropdown)
            .initialValue,
        2,
      );

      for (final capacity in [2, 3, 4, 5, 6]) {
        await tester.tap(capacityDropdown);
        await tester.pumpAndSettle();

        await tester.tap(find.text('$capacity jugadores').last);
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<DropdownButtonFormField<int>>(capacityDropdown)
              .initialValue,
          capacity,
        );
      }
    });

    testWidgets('muestra la entrada de código al unirse a una sala', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LobbyScreen(
            token: 'token',
            username: 'Invitado',
            joinMode: true,
          ),
        ),
      );

      expect(find.text('Unirse a sala'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Unirme a una sala'), findsOneWidget);
      expect(find.text('Crear sala'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<int> &&
              widget.decoration.labelText == 'Cantidad de jugadores',
        ),
        findsNothing,
      );
    });

    testWidgets('previsualiza los cuatro tableros antes de crear la sala', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LobbyScreen(token: 'token', username: 'Anfitrión'),
        ),
      );

      for (var boardId = 1; boardId <= 4; boardId++) {
        expect(find.byKey(ValueKey('creation-board-$boardId')), findsOneWidget);
        expect(
          find.byKey(ValueKey('creation-board-card-$boardId')),
          findsOneWidget,
        );
      }

      expect(find.text('Selecciona el tablero'), findsOneWidget);
      expect(find.text('Tablero compartido'), findsNothing);
      expect(find.byType(Scrollbar), findsOneWidget);

      final thirdBoard = find.byKey(const ValueKey('creation-board-3'));
      await tester.ensureVisible(thirdBoard);
      await tester.pumpAndSettle();
      await tester.tap(thirdBoard);
      await tester.pumpAndSettle();
      expect(find.text('Tablero 3 · Seleccionado'), findsOneWidget);
    });
  });

  group('Modo Ranked (Clasificatoria) y niveles en sala de espera', () {
    test('asigna el nivel de ranked según los puntos acumulados', () {
      expect(obtenerNivelRanked(0), 'Principiante');
      expect(obtenerNivelRanked(100), 'Principiante');
      expect(obtenerNivelRanked(299), 'Principiante');
      expect(obtenerNivelRanked(300), 'Nuevo héroe');
      expect(obtenerNivelRanked(499), 'Nuevo héroe');
      expect(obtenerNivelRanked(500), 'Experto');
      expect(obtenerNivelRanked(749), 'Experto');
      expect(obtenerNivelRanked(750), 'Megamente');
      expect(obtenerNivelRanked(1199), 'Megamente');
      expect(obtenerNivelRanked(1200), 'EL Brilliant');
      expect(obtenerNivelRanked(1800), 'EL Brilliant');
    });

    test(
      'no baja puntos al perder contra un jugador destacado por encima de ti',
      () {
        final delta = calcularCambioPuntosRanked(
          puntosPartida: 18,
          misPuntosRanked: 100,
          rivalesPuntosRanked: const [300],
          esGanador: false,
          ganadorPuntosRanked: 300,
          puntosGanadorPartida: 26,
        );

        expect(delta, 0);
        expect(
          aplicarCambioPuntosRanked(misPuntosRanked: 100, cambio: delta),
          100,
        );
      },
    );

    test(
      'aumenta un 20% los puntos ganados al vencer a un jugador por encima de ti',
      () {
        final delta = calcularCambioPuntosRanked(
          puntosPartida: 25,
          misPuntosRanked: 100,
          rivalesPuntosRanked: const [300],
          esGanador: true,
        );

        expect(delta, 30); // 25 + 20% = 30
        expect(
          aplicarCambioPuntosRanked(misPuntosRanked: 100, cambio: delta),
          130,
        );
      },
    );

    test(
      'suma puntos normales al ganar a un rival de igual o menor rango y resta al perder contra uno no superior',
      () {
        final winDelta = calcularCambioPuntosRanked(
          puntosPartida: 26,
          misPuntosRanked: 500,
          rivalesPuntosRanked: const [300],
          esGanador: true,
        );
        expect(winDelta, 26);

        final lossDelta = calcularCambioPuntosRanked(
          puntosPartida: 18,
          misPuntosRanked: 500,
          rivalesPuntosRanked: const [300],
          esGanador: false,
          ganadorPuntosRanked: 300,
          puntosGanadorPartida: 26,
        );
        expect(lossDelta, -8);
        expect(
          aplicarCambioPuntosRanked(misPuntosRanked: 500, cambio: lossDelta),
          492,
        );
      },
    );

    testWidgets(
      'muestra los 5 niveles de ranked en la sala de espera según puntos acumulados',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fakeService = _FakeLobbyMultiplayerService()
          ..room = const MultiplayerRoom(
            code: 'RANK01',
            hostId: 'p1',
            capacity: 5,
            boardId: 1,
            targetPoints: 21,
            status: 'waiting',
            ranked: true,
            players: [
              MultiplayerPlayer(
                id: 'p1',
                username: 'Ana',
                ready: true,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: false,
                rankedPoints: 100,
              ),
              MultiplayerPlayer(
                id: 'p2',
                username: 'Luis',
                ready: false,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: false,
                rankedPoints: 300,
              ),
              MultiplayerPlayer(
                id: 'p3',
                username: 'Marta',
                ready: true,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: false,
                rankedPoints: 500,
              ),
              MultiplayerPlayer(
                id: 'p4',
                username: 'Carlos',
                ready: false,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: false,
                rankedPoints: 750,
              ),
              MultiplayerPlayer(
                id: 'p5',
                username: 'Elena',
                ready: true,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: false,
                rankedPoints: 1200,
              ),
            ],
          );

        await tester.pumpWidget(
          MaterialApp(
            home: LobbyScreen(
              token: 'token',
              username: 'Ana',
              service: fakeService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Modo Clasificatoria (Ranked)'), findsOneWidget);
        expect(
          find.text('Principiante (100 puntos acumulados)'),
          findsOneWidget,
        );
        expect(
          find.text('Nuevo héroe (300 puntos acumulados)'),
          findsOneWidget,
        );
        expect(find.text('Experto (500 puntos acumulados)'), findsOneWidget);
        expect(find.text('Megamente (750 puntos acumulados)'), findsOneWidget);
        expect(
          find.text('EL Brilliant (1200 puntos acumulados)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'permite salir de una sala en espera y crear otra de inmediato sin error',
      (tester) async {
        final fakeService = _FakeLobbyMultiplayerService(
          initialRankedPoints: 300,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: LobbyScreen(
              token: 'token',
              username: 'Anfitrión',
              service: fakeService,
            ),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('ranked-mode-switch')));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        final createButton = find.byKey(const ValueKey('create-room-button'));
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        expect(fakeService.createCalls, 1);
        expect(fakeService.lastCreatedRanked, isTrue);
        expect(find.text('ROOM01'), findsOneWidget);
        expect(
          find.text('Nuevo héroe (300 puntos acumulados)'),
          findsOneWidget,
        );

        await tester.tap(find.text('Salir de la sala'));
        await tester.pumpAndSettle();

        expect(fakeService.leaveCalls, 1);
        expect(find.text('ROOM01'), findsNothing);

        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create-room-button')));
        await tester.pumpAndSettle();

        expect(fakeService.createCalls, 2);
        expect(find.text('ROOM02'), findsOneWidget);
      },
    );
  });
}
