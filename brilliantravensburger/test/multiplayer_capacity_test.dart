import 'dart:async';

import 'package:brilliantravensburger/hall_of_fame_widget.dart';
import 'package:brilliantravensburger/lobby_screen.dart';
import 'package:brilliantravensburger/multiplayer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLobbyMultiplayerService implements MultiplayerService {
  _FakeLobbyMultiplayerService({this.initialRankedPoints = 100});

  final Set<VoidCallback> _listeners = {};
  final int initialRankedPoints;
  final String username = 'Anfitrión';
  int createCalls = 0;
  int joinCalls = 0;
  int leaveCalls = 0;
  int disposeCalls = 0;
  bool lastCreatedRanked = false;
  bool lastCreatedTimeTrial = false;
  bool connected = true;
  Completer<void>? pendingCreateCompleter;

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  void notifyListeners() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  @override
  bool get hasListeners => _listeners.isNotEmpty;

  @override
  MultiplayerRoom? room;

  @override
  MultiplayerGameState? game;

  @override
  String? playerId = 'player-host';

  @override
  String? lastError;

  @override
  bool get isConnected => connected;

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
    bool timeTrial = false,
  }) async {
    createCalls++;
    lastCreatedRanked = ranked;
    lastCreatedTimeTrial = timeTrial;
    if (pendingCreateCompleter != null) {
      await pendingCreateCompleter!.future;
    }
    room = MultiplayerRoom(
      code: 'ROOM0$createCalls',
      hostId: 'player-host',
      capacity: capacity,
      boardId: boardId,
      targetPoints: 26,
      status: 'waiting',
      ranked: ranked,
      timeTrial: timeTrial,
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

  @override
  void dispose() {
    disposeCalls++;
    if (room != null) {
      leaveCalls++;
      room = null;
    }
    _listeners.clear();
  }
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
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

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
    test('asigna el nivel de ranked según el ELO', () {
      expect(obtenerNivelRanked(100), 'Principiante');
      expect(obtenerNivelRanked(999), 'Principiante');
      expect(obtenerNivelRanked(1000), 'Nuevo héroe');
      expect(obtenerNivelRanked(1149), 'Nuevo héroe');
      expect(obtenerNivelRanked(1150), 'Experto');
      expect(obtenerNivelRanked(1299), 'Experto');
      expect(obtenerNivelRanked(1300), 'Megamente');
      expect(obtenerNivelRanked(1499), 'Megamente');
      expect(obtenerNivelRanked(1500), 'EL Brilliant');
      expect(obtenerNivelRanked(1800), 'EL Brilliant');
    });

    test('usa factor K dinámico: 40 primeras 10 partidas, 32 normal y 24 en EL Brilliant', () {
      expect(obtenerFactorKElo(elo: 1000, partidasRanked: 0), 40);
      expect(obtenerFactorKElo(elo: 1600, partidasRanked: 9), 40);
      expect(obtenerFactorKElo(elo: 1000, partidasRanked: 10), 32);
      expect(obtenerFactorKElo(elo: 1499, partidasRanked: 25), 32);
      expect(obtenerFactorKElo(elo: 1500, partidasRanked: 10), 24);
    });

    test('calcula ELO multijugador por pares en salas de 2 y 3 jugadores y empates', () {
      // 2 jugadores iguales (1000 vs 1000, K=40): +20 / -20
      final duelo = calcularCambiosEloMultijugador(const [
        MultiplayerPlayer(
          id: 'p1',
          username: 'Ana',
          ready: true,
          connected: true,
          score: 30,
          finished: true,
          setupComplete: true,
          rankedPoints: 1000,
          rankedGames: 0,
        ),
        MultiplayerPlayer(
          id: 'p2',
          username: 'Luis',
          ready: true,
          connected: true,
          score: 18,
          finished: true,
          setupComplete: true,
          rankedPoints: 1000,
          rankedGames: 0,
        ),
      ]);
      expect(duelo['p1'], 20);
      expect(duelo['p2'], -20);

      // 3 jugadores FFA normalizado por N-1: menor ELO que gana a 2 superiores gana más
      final ffa = calcularCambiosEloMultijugador(const [
        MultiplayerPlayer(
          id: 'p1',
          username: 'Ana',
          ready: true,
          connected: true,
          score: 42,
          finished: true,
          setupComplete: true,
          rankedPoints: 1000,
          rankedGames: 15,
        ),
        MultiplayerPlayer(
          id: 'p2',
          username: 'Luis',
          ready: true,
          connected: true,
          score: 30,
          finished: true,
          setupComplete: true,
          rankedPoints: 1200,
          rankedGames: 15,
        ),
        MultiplayerPlayer(
          id: 'p3',
          username: 'Marta',
          ready: true,
          connected: true,
          score: 20,
          finished: true,
          setupComplete: true,
          rankedPoints: 1400,
          rankedGames: 15,
        ),
      ]);
      expect(ffa['p1']!, greaterThan(20));
      expect(ffa['p3']!, lessThan(-20));

      // Empate entre iguales: 0 cambio
      final empate = calcularCambiosEloMultijugador(const [
        MultiplayerPlayer(
          id: 'p1',
          username: 'Ana',
          ready: true,
          connected: true,
          score: 25,
          finished: true,
          setupComplete: true,
          rankedPoints: 1000,
          rankedGames: 10,
        ),
        MultiplayerPlayer(
          id: 'p2',
          username: 'Luis',
          ready: true,
          connected: true,
          score: 25,
          finished: true,
          setupComplete: true,
          rankedPoints: 1000,
          rankedGames: 10,
        ),
      ]);
      expect(empate['p1'], 0);
      expect(empate['p2'], 0);

      // Compensación por ranked injusto:
      // Brecha >= 200 pts abajo: pérdida reducida al 50% (-10 -> -5)
      final brecha200 = calcularResultadosEloMultijugador(const [
        MultiplayerPlayer(
          id: 'fav',
          username: 'Luis',
          ready: true,
          connected: true,
          score: 30,
          finished: true,
          setupComplete: true,
          rankedPoints: 1200,
          rankedGames: 0,
        ),
        MultiplayerPlayer(
          id: 'dog',
          username: 'Ana',
          ready: true,
          connected: true,
          score: 15,
          finished: true,
          setupComplete: true,
          rankedPoints: 1000,
          rankedGames: 0,
        ),
      ]);
      expect(brecha200['dog']!.delta, -5);
      expect(brecha200['dog']!.compensacion, contains('-50%'));

      // Brecha >= 300 pts / >= 2 rangos abajo: 0 pts perdidos
      final brecha300 = calcularResultadosEloMultijugador(const [
        MultiplayerPlayer(
          id: 'fav',
          username: 'Luis',
          ready: true,
          connected: true,
          score: 30,
          finished: true,
          setupComplete: true,
          rankedPoints: 1300,
          rankedGames: 0,
        ),
        MultiplayerPlayer(
          id: 'dog',
          username: 'Ana',
          ready: true,
          connected: true,
          score: 15,
          finished: true,
          setupComplete: true,
          rankedPoints: 1000,
          rankedGames: 0,
        ),
      ]);
      expect(brecha300['dog']!.delta, 0);
      expect(brecha300['dog']!.compensacion, contains('0 pts perdidos'));

      // Victoria contra rival >= 200 pts arriba: +20% extra (+30 -> +36)
      final victoriaSuperior = calcularResultadosEloMultijugador(const [
        MultiplayerPlayer(
          id: 'dog',
          username: 'Ana',
          ready: true,
          connected: true,
          score: 30,
          finished: true,
          setupComplete: true,
          rankedPoints: 1000,
          rankedGames: 0,
        ),
        MultiplayerPlayer(
          id: 'fav',
          username: 'Luis',
          ready: true,
          connected: true,
          score: 15,
          finished: true,
          setupComplete: true,
          rankedPoints: 1200,
          rankedGames: 0,
        ),
      ]);
      expect(victoriaSuperior['dog']!.delta, 36);
      expect(victoriaSuperior['dog']!.compensacion, contains('+20%'));
    });

    testWidgets(
      'muestra los 5 niveles de ranked y ELO en la sala de espera',
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
                rankedPoints: 900,
              ),
              MultiplayerPlayer(
                id: 'p2',
                username: 'Luis',
                ready: false,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: false,
                rankedPoints: 1000,
              ),
              MultiplayerPlayer(
                id: 'p3',
                username: 'Marta',
                ready: true,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: false,
                rankedPoints: 1150,
              ),
              MultiplayerPlayer(
                id: 'p4',
                username: 'Carlos',
                ready: false,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: false,
                rankedPoints: 1300,
              ),
              MultiplayerPlayer(
                id: 'p5',
                username: 'Elena',
                ready: true,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: false,
                rankedPoints: 1500,
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
        expect(find.byKey(const ValueKey('ranked-compensation-banner')), findsOneWidget);
        expect(find.text('Principiante (900 pts)'), findsOneWidget);
        expect(find.text('Nuevo héroe (1000 pts)'), findsOneWidget);
        expect(find.text('Experto (1150 pts)'), findsOneWidget);
        expect(find.text('Megamente (1300 pts)'), findsOneWidget);
        expect(find.text('EL Brilliant (1500 pts)'), findsOneWidget);
      },
    );

    testWidgets(
      'permite salir de una sala en espera y crear otra de inmediato sin error',
      (tester) async {
        final fakeService = _FakeLobbyMultiplayerService(
          initialRankedPoints: 1000,
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

        await tester.drag(find.byType(ListView).first, const Offset(0, -450));
        await tester.pumpAndSettle();
        final createButton = find.byKey(const ValueKey('create-room-button'));
        await tester.ensureVisible(createButton);
        await tester.pumpAndSettle();
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        expect(fakeService.createCalls, 1);
        expect(fakeService.lastCreatedRanked, isTrue);
        expect(find.text('ROOM01'), findsOneWidget);
        expect(find.text('Nuevo héroe (1000 pts)'), findsOneWidget);

        await tester.tap(find.text('Salir de la sala'));
        await tester.pumpAndSettle();

        expect(fakeService.leaveCalls, 1);
        expect(find.text('ROOM01'), findsNothing);

        await tester.drag(find.byType(ListView).first, const Offset(0, -450));
        await tester.pumpAndSettle();
        await tester.ensureVisible(createButton);
        await tester.pumpAndSettle();
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        expect(fakeService.createCalls, 2);
        expect(find.text('ROOM02'), findsOneWidget);
      },
    );

    test(
      'serializa y deserializa campos de clasificatoria en sala y jugador',
      () {
        final room = MultiplayerRoom.fromJson({
          'code': 'RANK99',
          'hostId': 'p1',
          'capacity': 2,
          'boardId': 2,
          'targetPoints': 26,
          'status': 'finished',
          'ranked': true,
          'players': [
            {
              'id': 'p1',
              'username': 'Ana',
              'ready': true,
              'connected': true,
              'score': 25,
              'finished': true,
              'setupComplete': true,
              'rankedPoints': 980,
              'rankedGames': 5,
              'rankedDelta': 30,
            },
            {
              'id': 'p2',
              'username': 'Luis',
              'ready': true,
              'connected': true,
              'score': 18,
              'finished': true,
              'setupComplete': true,
              'rankedPoints': 1170,
              'rankedGames': 12,
              'rankedDelta': -30,
            },
          ],
        });

        expect(room.ranked, isTrue);
        expect(room.players.first.rankedPoints, 980);
        expect(room.players.first.rankedGames, 5);
        expect(room.players.first.rankedDelta, 30);
        expect(room.players.first.rankedLevel, 'Principiante');
        expect(room.players.first.rankedTier, 0);
        expect(room.players.last.rankedPoints, 1170);
        expect(room.players.last.rankedGames, 12);
        expect(room.players.last.rankedDelta, -30);
        expect(room.players.last.rankedLevel, 'Experto');
        expect(room.players.last.rankedTier, 2);
      },
    );

    test(
      'nunca reduce el ELO por debajo del piso mínimo de 100 al perder',
      () {
        final delta = calcularCambioPuntosRanked(
          puntosPartida: 5,
          misPuntosRanked: 105,
          rivalesPuntosRanked: const [105],
          esGanador: false,
          puntosGanadorPartida: 26,
        );

        expect(delta, -5);
        expect(
          aplicarCambioPuntosRanked(misPuntosRanked: 105, cambio: delta),
          100,
        );
      },
    );

    testWidgets(
      'cancela una sala mientras se está creando y permite crear o unirse a otra al primer intento',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final firstService = _FakeLobbyMultiplayerService(
          initialRankedPoints: 900,
        )..pendingCreateCompleter = Completer<void>();

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LobbyScreen(
                            token: 'token',
                            username: 'Anfitrión',
                            service: firstService,
                          ),
                        ),
                      );
                    },
                    child: const Text('Abrir lobby'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir lobby'));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create-room-button')));
        await tester.pump();

        expect(firstService.createCalls, 1);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // El usuario cancela / retrocede mientras la sala se está generando
        await tester.binding.handlePopRoute();
        await tester.pump();

        // Termina la petición en curso y debe limpiar la sala automáticamente
        firstService.pendingCreateCompleter!.complete();
        await tester.pumpAndSettle();

        expect(firstService.leaveCalls, greaterThanOrEqualTo(1));
        expect(firstService.room, isNull);
        expect(find.text('Abrir lobby'), findsOneWidget);

        // Al volver a entrar y crear otra sala o unirse, funciona al primer intento
        final secondService = _FakeLobbyMultiplayerService(
          initialRankedPoints: 1150,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: LobbyScreen(
              token: 'token',
              username: 'Anfitrión',
              service: secondService,
            ),
          ),
        );

        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create-room-button')));
        await tester.pumpAndSettle();

        expect(secondService.createCalls, 1);
        expect(find.text('ROOM01'), findsOneWidget);
        expect(find.text('Experto (1150 pts)'), findsOneWidget);
      },
    );

    testWidgets(
      'sale de una sala en espera con el botón atrás y permite unirse a otra sala al primer intento',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final hostService = _FakeLobbyMultiplayerService(
          initialRankedPoints: 1300,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LobbyScreen(
                              token: 'token',
                              username: 'Anfitrión',
                              service: hostService,
                            ),
                          ),
                        );
                      },
                      child: const Text('Ir a crear'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LobbyScreen(
                              token: 'token',
                              username: 'Anfitrión',
                              joinMode: true,
                              service: hostService,
                            ),
                          ),
                        );
                      },
                      child: const Text('Ir a unirse'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Ir a crear'));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create-room-button')));
        await tester.pumpAndSettle();

        expect(find.text('ROOM01'), findsOneWidget);
        expect(find.text('Megamente (1300 pts)'), findsOneWidget);

        // Sale de la sala en espera usando navegación hacia atrás
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(hostService.leaveCalls, greaterThanOrEqualTo(1));
        expect(hostService.room, isNull);
        expect(find.text('Ir a unirse'), findsOneWidget);

        // Ahora entra a otra sala y funciona al primer intento sin error
        await tester.tap(find.text('Ir a unirse'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'ab12cd');
        await tester.tap(find.text('Unirme a una sala'));
        await tester.pumpAndSettle();

        expect(hostService.joinCalls, 1);
        expect(find.text('AB12CD'), findsOneWidget);
        expect(find.text('Megamente (1300 pts)'), findsOneWidget);
      },
    );

    testWidgets(
      'permite activar y desactivar el modo Contra reloj al crear la sala',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = _FakeLobbyMultiplayerService();

        await tester.pumpWidget(
          MaterialApp(
            home: LobbyScreen(
              token: 'token',
              username: 'Anfitrión',
              service: service,
            ),
          ),
        );

        expect(find.text('Contra reloj'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('time-trial-mode-switch')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('create-room-button')));
        await tester.pumpAndSettle();

        expect(service.lastCreatedTimeTrial, isTrue);
        expect(find.byKey(const ValueKey('room-time-trial-badge')), findsOneWidget);
        expect(find.text('⏱ Contra reloj (2 min)'), findsOneWidget);

        await tester.tap(find.text('Salir de la sala'));
        await tester.pumpAndSettle();

        // Desactivar Contra reloj y volver a crear la sala
        await tester.tap(find.byKey(const ValueKey('time-trial-mode-switch')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create-room-button')));
        await tester.pumpAndSettle();

        expect(service.lastCreatedTimeTrial, isFalse);
        expect(find.byKey(const ValueKey('room-time-trial-badge')), findsNothing);
      },
    );

    testWidgets(
      'muestra los 4 tableros sin recorte en pantalla ancha de Windows dentro de la sala',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = _FakeLobbyMultiplayerService()
          ..room = const MultiplayerRoom(
            code: 'WIN001',
            hostId: 'player-host',
            capacity: 2,
            boardId: 2,
            targetPoints: 26,
            status: 'waiting',
            players: [
              MultiplayerPlayer(
                id: 'player-host',
                username: 'simon',
                ready: false,
                connected: true,
                score: 0,
                finished: false,
                setupComplete: false,
                rankedPoints: 0,
              ),
            ],
          );

        await tester.pumpWidget(
          MaterialApp(
            home: LobbyScreen(
              token: 'token',
              username: 'simon',
              service: service,
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (var boardId = 1; boardId <= 4; boardId++) {
          final cardFinder = find.byKey(ValueKey('room-board-$boardId'));
          expect(cardFinder, findsOneWidget);
          final size = tester.getSize(cardFinder);
          expect(size.height, greaterThanOrEqualTo(56));
          expect(size.height, lessThanOrEqualTo(80));
        }
        expect(find.text('Tablero 2\nEn uso'), findsOneWidget);
      },
    );

    testWidgets(
      'muestra reglas e información de modos de juego y adapta colores activos en modo oscuro',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = _FakeLobbyMultiplayerService();

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: LobbyScreen(
              token: 'token',
              username: 'Anfitrión',
              service: service,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('ranked-mode-switch')));
        await tester.tap(find.byKey(const ValueKey('time-trial-mode-switch')));
        await tester.pumpAndSettle();

        final rankedTile = tester.widget<SwitchListTile>(
          find.byKey(const ValueKey('ranked-mode-switch')),
        );
        final timeTrialTile = tester.widget<SwitchListTile>(
          find.byKey(const ValueKey('time-trial-mode-switch')),
        );
        // En modo oscuro los cuadros activos usan tonos oscuros con alto contraste (no shade50 pálido)
        expect(rankedTile.tileColor, const Color(0xFF4A3210));
        expect(timeTrialTile.tileColor, const Color(0xFF4A2511));

        await tester.tap(find.byKey(const ValueKey('lobby-modes-info-button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('game-modes-info-dialog')), findsOneWidget);
        expect(find.text('Reglas y modos de juego'), findsOneWidget);
        expect(find.text('Reglas básicas'), findsOneWidget);
        expect(find.text('Modo Contra reloj'), findsOneWidget);
      },
    );

    testWidgets(
      'abre el Salón de la Fama desde Crear sala mostrando Top 10 y posición propia fuera del Top 10',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        HallOfFameService.testLoader = (token) async => HallOfFameData(
          top10: [
            for (var i = 1; i <= 10; i++)
              HallOfFameEntry(
                position: i,
                id: 'top-$i',
                username: 'TopJugador$i',
                rankedPoints: 1700 - (i * 25),
                rankedLevel: obtenerNivelRanked(1700 - (i * 25)),
              ),
          ],
          currentUser: const HallOfFameEntry(
            position: 15,
            id: 'me-15',
            username: 'MiUsuario',
            rankedPoints: 1020,
            rankedLevel: 'Nuevo héroe',
          ),
        );
        addTearDown(() => HallOfFameService.testLoader = null);

        final service = _FakeLobbyMultiplayerService();
        await tester.pumpWidget(
          MaterialApp(
            home: LobbyScreen(
              token: 'token',
              username: 'MiUsuario',
              service: service,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final hallButton = find.byKey(const ValueKey('lobby-hall-of-fame-button'));
        expect(hallButton, findsOneWidget);
        await tester.tap(hallButton);
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('hall-of-fame-dialog')), findsOneWidget);
        expect(find.text('Salón de la Fama · Top 10'), findsOneWidget);
        expect(find.text('TopJugador1'), findsOneWidget);
        expect(find.byKey(const ValueKey('hall-of-fame-current-user')), findsOneWidget);
        expect(find.text('MiUsuario (Tú)'), findsOneWidget);
        expect(find.text('#15'), findsOneWidget);
        expect(find.text('1020 pts'), findsOneWidget);
      },
    );
  });
}
