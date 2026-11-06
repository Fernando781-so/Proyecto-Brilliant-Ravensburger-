import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'app_config.dart';

class MultiplayerPlayer {
  const MultiplayerPlayer({
    required this.id,
    required this.username,
    required this.ready,
    required this.connected,
    required this.score,
    required this.finished,
  });

  final String id;
  final String username;
  final bool ready;
  final bool connected;
  final int score;
  final bool finished;

  factory MultiplayerPlayer.fromJson(Map<String, dynamic> json) {
    return MultiplayerPlayer(
      id: '${json['id']}',
      username: '${json['username'] ?? 'Jugador'}',
      ready: json['ready'] == true,
      connected: json['connected'] != false,
      score: (json['score'] as num?)?.toInt() ?? 0,
      finished: json['finished'] == true,
    );
  }
}

class MultiplayerRoom {
  const MultiplayerRoom({
    required this.code,
    required this.hostId,
    required this.capacity,
    required this.boardId,
    required this.targetPoints,
    required this.status,
    required this.players,
  });

  final String code;
  final String hostId;
  final int capacity;
  final int boardId;
  final int targetPoints;
  final String status;
  final List<MultiplayerPlayer> players;

  factory MultiplayerRoom.fromJson(Map<String, dynamic> json) {
    return MultiplayerRoom(
      code: '${json['code']}',
      hostId: '${json['hostId']}',
      capacity: (json['capacity'] as num).toInt(),
      boardId: (json['boardId'] as num).toInt(),
      targetPoints: (json['targetPoints'] as num).toInt(),
      status: '${json['status']}',
      players: (json['players'] as List<dynamic>? ?? const [])
          .map(
            (player) => MultiplayerPlayer.fromJson(
              Map<String, dynamic>.from(player as Map),
            ),
          )
          .toList(),
    );
  }
}

class MultiplayerGameState {
  const MultiplayerGameState({
    required this.turn,
    required this.dice,
    required this.completedPlayerIds,
    required this.zoneClaims,
    required this.winnerId,
  });

  final int turn;
  final List<int> dice;
  final Set<String> completedPlayerIds;
  final Map<int, List<Map<String, dynamic>>> zoneClaims;
  final String? winnerId;

  factory MultiplayerGameState.fromJson(Map<String, dynamic> json) {
    final claims = <int, List<Map<String, dynamic>>>{};
    final rawClaims = Map<String, dynamic>.from(
      json['zoneClaims'] as Map? ?? const {},
    );
    for (final entry in rawClaims.entries) {
      claims[int.parse(entry.key)] = (entry.value as List<dynamic>)
          .map((claim) => Map<String, dynamic>.from(claim as Map))
          .toList();
    }

    return MultiplayerGameState(
      turn: (json['turn'] as num?)?.toInt() ?? 1,
      dice: (json['dice'] as List<dynamic>? ?? const [1, 1])
          .map((value) => (value as num).toInt())
          .toList(),
      completedPlayerIds:
          (json['completedPlayerIds'] as List<dynamic>? ?? const [])
              .map((id) => '$id')
              .toSet(),
      zoneClaims: claims,
      winnerId: json['winnerId']?.toString(),
    );
  }
}

class MultiplayerService extends ChangeNotifier {
  MultiplayerService._(this._socket);

  final socket_io.Socket _socket;
  MultiplayerRoom? room;
  MultiplayerGameState? game;
  String? playerId;
  String? lastError;
  List<int>? _myBoard;

  bool get isConnected => _socket.connected;

  int get myScore {
    for (final player in room?.players ?? const <MultiplayerPlayer>[]) {
      if (player.id == playerId) return player.score;
    }
    return 0;
  }

  bool get myTurnIsComplete =>
      game?.completedPlayerIds.contains(playerId) ?? false;

  bool get myBoardIsComplete {
    for (final player in room?.players ?? const <MultiplayerPlayer>[]) {
      if (player.id == playerId) return player.finished;
    }
    return false;
  }

  List<int>? get myBoard => _myBoard == null ? null : List.of(_myBoard!);

  static Future<MultiplayerService> connect({required String token}) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(path: '', query: null, fragment: null);
    final socket = socket_io.io(uri.toString(), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });
    final service = MultiplayerService._(socket);
    service._registerListeners();

    final connected = Completer<void>();
    socket.onConnect((_) {
      if (!connected.isCompleted) {
        connected.complete();
      } else if (service.room != null) {
        unawaited(service._restoreRoom());
      }
    });
    socket.onConnectError((error) {
      if (!connected.isCompleted) {
        connected.completeError(
          Exception(
            error is Map
                ? error['message'] ?? 'No se pudo conectar al servidor.'
                : '$error',
          ),
        );
      }
    });
    socket.connect();

    try {
      await connected.future.timeout(const Duration(seconds: 12));
      return service;
    } catch (_) {
      service.dispose();
      rethrow;
    }
  }

  void _registerListeners() {
    _socket.on('lobby:update', (data) {
      _setRoom(Map<String, dynamic>.from(data as Map));
    });
    _socket.on('game:start', (data) {
      _setGameSnapshot(Map<String, dynamic>.from(data as Map));
    });
    _socket.on('game:state', (data) {
      _setGameSnapshot(Map<String, dynamic>.from(data as Map));
    });
    _socket.on('app:error', (data) {
      lastError = '$data';
      notifyListeners();
    });
  }

  void _setRoom(Map<String, dynamic> json) {
    room = MultiplayerRoom.fromJson(json);
    notifyListeners();
  }

  void _setGameSnapshot(Map<String, dynamic> json) {
    _setRoom(Map<String, dynamic>.from(json['room'] as Map));
    game = MultiplayerGameState.fromJson(json);
    if (json.containsKey('ownBoard')) {
      final board = json['ownBoard'] as List<dynamic>?;
      _myBoard = board?.map((value) => (value as num).toInt()).toList();
    }
    lastError = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> _request(
    String event,
    Map<String, dynamic> payload,
  ) async {
    final completer = Completer<Map<String, dynamic>>();
    _socket.emitWithAck(
      event,
      payload,
      ack: (dynamic response) {
        if (completer.isCompleted) return;
        if (response is! Map) {
          completer.completeError(
            Exception('Respuesta inválida del servidor.'),
          );
          return;
        }
        final data = Map<String, dynamic>.from(response);
        if (data['ok'] != true) {
          completer.completeError(
            Exception(data['error'] ?? 'No se pudo completar la solicitud.'),
          );
        } else {
          completer.complete(data);
        }
      },
    );
    return completer.future.timeout(const Duration(seconds: 12));
  }

  Future<void> createRoom({
    required int capacity,
    required int boardId,
    required List<List<int>> zonePointValues,
  }) async {
    final result = await _request('lobby:create', {
      'capacity': capacity,
      'boardId': boardId,
      'zonePointValues': zonePointValues,
    });
    _acceptRoomResult(result);
  }

  Future<void> joinRoom(String code) async {
    final result = await _request('lobby:join', {'code': code});
    _acceptRoomResult(result);
  }

  Future<void> _restoreRoom() async {
    final code = room?.code;
    if (code == null) return;
    try {
      await joinRoom(code);
    } catch (error) {
      lastError = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void _acceptRoomResult(Map<String, dynamic> result) {
    final nextRoom = MultiplayerRoom.fromJson(
      Map<String, dynamic>.from(result['room'] as Map),
    );
    if (room?.code != nextRoom.code) {
      game = null;
      _myBoard = null;
    }
    playerId = '${result['playerId']}';
    room = nextRoom;
    lastError = null;
    notifyListeners();
  }

  Future<void> setReady(bool ready) async {
    final result = await _request('lobby:ready', {'ready': ready});
    _setRoom(Map<String, dynamic>.from(result['room'] as Map));
  }

  Future<void> setBoard({
    required int boardId,
    required List<List<int>> zonePointValues,
  }) async {
    final result = await _request('lobby:board', {
      'boardId': boardId,
      'zonePointValues': zonePointValues,
    });
    _setRoom(Map<String, dynamic>.from(result['room'] as Map));
  }

  Future<void> completeTurn({
    required List<int> board,
    required List<int> completedZones,
    required bool finished,
  }) async {
    _myBoard = List.of(board);
    final result = await _request('game:turn-complete', {
      'board': board,
      'completedZones': completedZones,
      'finished': finished,
    });
    _setGameSnapshot(Map<String, dynamic>.from(result['state'] as Map));
  }

  Future<void> leaveRoom() async {
    await _request('lobby:leave', const {});
    room = null;
    game = null;
    playerId = null;
    _myBoard = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }
}
