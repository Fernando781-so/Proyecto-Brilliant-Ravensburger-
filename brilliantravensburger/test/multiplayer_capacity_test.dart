import 'package:brilliantravensburger/lobby_screen.dart';
import 'package:brilliantravensburger/multiplayer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      expect(game.completedPlayerIds, {'player-1', 'player-2'});
      expect(game.zoneClaims.keys, containsAll([1, 4]));
      expect(game.zoneClaims[1], [
        {'playerId': 'player-1', 'points': 10},
      ]);
      expect(game.zoneClaims[4], hasLength(2));
      expect(game.winnerId, 'player-1');
    });
  });

  group('Partidas multijugador por cantidad de jugadores', () {
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
  });
}
