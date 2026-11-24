import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'app_config.dart';

const Duration duracionTurnoContraReloj = Duration(minutes: 2);
const Duration duracionInicioContraReloj = Duration(minutes: 5);

String formatearTiempoContraReloj(int segundosTotales) {
  final seguros = max(0, segundosTotales);
  final minutos = (seguros ~/ 60).toString().padLeft(2, '0');
  final segundos = (seguros % 60).toString().padLeft(2, '0');
  return '$minutos:$segundos';
}

const int eloInicial = 1000;
const int eloMinimo = 100;
const int eloFactorKProvisional = 40;
const int eloFactorKNormal = 32;
const int eloFactorKMaestro = 24;

String obtenerNivelRanked(int elo) {
  if (elo >= 1500) return 'EL Brilliant';
  if (elo >= 1300) return 'Megamente';
  if (elo >= 1150) return 'Experto';
  if (elo >= 1000) return 'Nuevo héroe';
  return 'Principiante';
}

int obtenerIndiceNivelRanked(int elo) {
  if (elo >= 1500) return 4;
  if (elo >= 1300) return 3;
  if (elo >= 1150) return 2;
  if (elo >= 1000) return 1;
  return 0;
}

int obtenerFactorKElo({required int elo, int partidasRanked = 0}) {
  if (partidasRanked < 10) return eloFactorKProvisional;
  if (elo >= 1500) return eloFactorKMaestro;
  return eloFactorKNormal;
}

Map<String, int> calcularCambiosEloMultijugador(
  List<MultiplayerPlayer> jugadores, {
  String? winnerId,
}) {
  final cambios = <String, int>{};
  if (jugadores.length < 2) {
    for (final jugador in jugadores) {
      cambios[jugador.id] = 0;
    }
    return cambios;
  }

  final cantidadRivales = jugadores.length - 1;
  for (final jugador in jugadores) {
    final eloPropio = max(eloMinimo, jugador.rankedPoints);
    final k = obtenerFactorKElo(
      elo: eloPropio,
      partidasRanked: jugador.rankedGames,
    );
    var sumaDiferencias = 0.0;

    for (final rival in jugadores) {
      if (rival.id == jugador.id) continue;
      final eloRival = max(eloMinimo, rival.rankedPoints);
      final esperado = 1.0 / (1.0 + pow(10, (eloRival - eloPropio) / 400.0));

      final double resultadoReal;
      if (jugador.score > rival.score) {
        resultadoReal = 1.0;
      } else if (jugador.score < rival.score) {
        resultadoReal = 0.0;
      } else if (winnerId != null && jugador.id == winnerId) {
        resultadoReal = 1.0;
      } else if (winnerId != null && rival.id == winnerId) {
        resultadoReal = 0.0;
      } else {
        resultadoReal = 0.5;
      }

      sumaDiferencias += resultadoReal - esperado;
    }

    final deltaBruto = ((k / cantidadRivales) * sumaDiferencias).round();
    final nuevoElo = max(eloMinimo, eloPropio + deltaBruto);
    cambios[jugador.id] = nuevoElo - eloPropio;
  }

  return cambios;
}

int calcularCambioPuntosRanked({
  required int puntosPartida,
  required int misPuntosRanked,
  required List<int> rivalesPuntosRanked,
  required bool esGanador,
  int misPartidasRanked = 0,
  List<int>? puntosRivalesPartida,
  int? ganadorPuntosRanked,
  int? puntosGanadorPartida,
}) {
  final participantes = <MultiplayerPlayer>[
    MultiplayerPlayer(
      id: 'self',
      username: 'self',
      ready: true,
      connected: true,
      score: max(0, puntosPartida),
      finished: true,
      setupComplete: true,
      rankedPoints: max(eloMinimo, misPuntosRanked),
      rankedGames: max(0, misPartidasRanked),
    ),
    for (var i = 0; i < rivalesPuntosRanked.length; i++)
      MultiplayerPlayer(
        id: 'opp-$i',
        username: 'opp-$i',
        ready: true,
        connected: true,
        score: puntosRivalesPartida != null && i < puntosRivalesPartida.length
            ? puntosRivalesPartida[i]
            : (esGanador
                  ? max(0, puntosPartida - 1)
                  : max(puntosPartida + 1, puntosGanadorPartida ?? 1)),
        finished: true,
        setupComplete: true,
        rankedPoints: max(eloMinimo, rivalesPuntosRanked[i]),
      ),
  ];
  return calcularCambiosEloMultijugador(
        participantes,
        winnerId: esGanador ? 'self' : null,
      )['self'] ??
      0;
}

int aplicarCambioPuntosRanked({
  required int misPuntosRanked,
  required int cambio,
}) {
  return max(eloMinimo, misPuntosRanked + cambio);
}

class MultiplayerPlayer {
  const MultiplayerPlayer({
    required this.id,
    required this.username,
    required this.ready,
    required this.connected,
    required this.score,
    required this.finished,
    required this.setupComplete,
    this.rankedPoints = eloInicial,
    this.rankedGames = 0,
    this.rankedDelta,
    this.board,
  });

  final String id;
  final String username;
  final bool ready;
  final bool connected;
  final int score;
  final bool finished;
  final bool setupComplete;
  final int rankedPoints;
  final int rankedGames;
  final int? rankedDelta;
  final List<int>? board;

  String get rankedLevel => obtenerNivelRanked(rankedPoints);

  int get rankedTier => obtenerIndiceNivelRanked(rankedPoints);

  factory MultiplayerPlayer.fromJson(Map<String, dynamic> json) {
    final rawBoard = json['board'] as List<dynamic>?;
    final parsedRanked = (json['rankedPoints'] as num?)?.toInt();
    return MultiplayerPlayer(
      id: '${json['id']}',
      username: '${json['username'] ?? 'Jugador'}',
      ready: json['ready'] == true,
      connected: json['connected'] != false,
      score: (json['score'] as num?)?.toInt() ?? 0,
      finished: json['finished'] == true,
      setupComplete: json['setupComplete'] == true,
      rankedPoints: parsedRanked != null
          ? max(eloMinimo, parsedRanked)
          : eloInicial,
      rankedGames: max(0, (json['rankedGames'] as num?)?.toInt() ?? 0),
      rankedDelta: (json['rankedDelta'] as num?)?.toInt(),
      board: rawBoard?.map((value) => (value as num).toInt()).toList(),
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
    this.ranked = false,
    this.timeTrial = false,
  });

  final String code;
  final String hostId;
  final int capacity;
  final int boardId;
  final int targetPoints;
  final String status;
  final List<MultiplayerPlayer> players;
  final bool ranked;
  final bool timeTrial;

  int get setupCompleteCount =>
      players.where((player) => player.setupComplete).length;

  bool get allPlayersSetupComplete =>
      players.isNotEmpty && players.every((player) => player.setupComplete);

  factory MultiplayerRoom.fromJson(Map<String, dynamic> json) {
    return MultiplayerRoom(
      code: '${json['code']}',
      hostId: '${json['hostId']}',
      capacity: (json['capacity'] as num).toInt(),
      boardId: (json['boardId'] as num).toInt(),
      targetPoints: (json['targetPoints'] as num).toInt(),
      status: '${json['status']}',
      ranked: json['ranked'] == true || json['mode'] == 'ranked',
      timeTrial: json['timeTrial'] == true || json['contraReloj'] == true,
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
    required this.phase,
    required this.setupCompletePlayerIds,
    required this.completedPlayerIds,
    required this.zoneClaims,
    required this.winnerId,
    this.playerBoards = const {},
  });

  final int turn;
  final List<int> dice;
  final String phase;
  final Set<String> setupCompletePlayerIds;
  final Set<String> completedPlayerIds;
  final Map<int, List<Map<String, dynamic>>> zoneClaims;
  final String? winnerId;
  final Map<String, List<int>> playerBoards;

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
    final playerBoards = <String, List<int>>{};
    final rawPlayerBoards = json['playerBoards'];
    if (rawPlayerBoards is Map) {
      for (final entry in rawPlayerBoards.entries) {
        final board = entry.value;
        if (board is List && board.every((value) => value is num)) {
          playerBoards['${entry.key}'] = board
              .map((value) => (value as num).toInt())
              .toList();
        }
      }
    }

    return MultiplayerGameState(
      turn: (json['turn'] as num?)?.toInt() ?? 1,
      dice: (json['dice'] as List<dynamic>? ?? const [1, 1])
          .map((value) => (value as num).toInt())
          .toList(),
      phase: '${json['phase'] ?? 'setup'}',
      setupCompletePlayerIds:
          (json['setupCompletePlayerIds'] as List<dynamic>? ?? const [])
              .map((id) => '$id')
              .toSet(),
      completedPlayerIds:
          (json['completedPlayerIds'] as List<dynamic>? ?? const [])
              .map((id) => '$id')
              .toSet(),
      zoneClaims: claims,
      winnerId: json['winnerId']?.toString(),
      playerBoards: playerBoards,
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
  bool _isRestoringRoom = false;
  bool _roomRestored = true;
  bool _awaitingGameSnapshot = false;
  bool _hasLeftRoom = false;

  bool get isConnected => _socket.connected;
  bool get canPlay => isConnected && !_isRestoringRoom && _roomRestored;

  int get myScore {
    for (final player in room?.players ?? const <MultiplayerPlayer>[]) {
      if (player.id == playerId) return player.score;
    }
    return 0;
  }

  bool get myTurnIsComplete =>
      game?.completedPlayerIds.contains(playerId) ?? false;

  bool get mySetupIsComplete =>
      game?.setupCompletePlayerIds.contains(playerId) ?? false;

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
    socket_io.cache.clear();
    final socket = socket_io.io(uri.toString(), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'forceNew': true,
      'multiplex': false,
      'auth': {'token': token},
    });
    final service = MultiplayerService._(socket);
    service._registerListeners();

    final connected = Completer<void>();
    socket.onConnect((_) {
      if (!connected.isCompleted) {
        connected.complete();
      } else if (service.room != null && !service._hasLeftRoom) {
        unawaited(service._restoreRoom());
      }
      service.notifyListeners();
    });
    socket.onDisconnect((_) {
      if (service.room != null && !service._hasLeftRoom) {
        service._roomRestored = false;
        service._awaitingGameSnapshot = service.room?.status == 'playing';
      }
      service.lastError = null;
      service.notifyListeners();
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
      if (_hasLeftRoom) return;
      _setRoom(Map<String, dynamic>.from(data as Map));
    });
    _socket.on('game:start', (data) {
      if (_hasLeftRoom) return;
      _setGameSnapshot(Map<String, dynamic>.from(data as Map));
    });
    _socket.on('game:state', (data) {
      if (_hasLeftRoom) return;
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
    _roomRestored = true;
    _awaitingGameSnapshot = false;
    lastError = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> _request(
    String event,
    Map<String, dynamic> payload,
  ) async {
    if (!_socket.connected) {
      throw Exception('Sin conexión con el servidor. Espera la reconexión.');
    }

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
    bool ranked = false,
    bool timeTrial = false,
  }) async {
    _hasLeftRoom = false;
    final result = await _request('lobby:create', {
      'capacity': capacity,
      'boardId': boardId,
      'zonePointValues': zonePointValues,
      'ranked': ranked,
      'timeTrial': timeTrial,
    });
    _acceptRoomResult(result);
  }

  Future<void> joinRoom(String code) async {
    _hasLeftRoom = false;
    final result = await _request('lobby:join', {'code': code});
    _acceptRoomResult(result);
  }

  Future<void> _restoreRoom() async {
    final code = room?.code;
    if (code == null ||
        _hasLeftRoom ||
        _isRestoringRoom ||
        !_socket.connected) {
      return;
    }
    _isRestoringRoom = true;
    _roomRestored = false;
    _awaitingGameSnapshot = room?.status == 'playing';
    lastError = null;
    notifyListeners();
    try {
      await joinRoom(code);
    } catch (error) {
      lastError = error.toString().replaceFirst('Exception: ', '');
      _roomRestored = false;
    } finally {
      _isRestoringRoom = false;
      notifyListeners();
    }
  }

  Future<void> retryRoomRestore() => _restoreRoom();

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
    _hasLeftRoom = false;
    _roomRestored =
        !_isRestoringRoom ||
        nextRoom.status != 'playing' ||
        !_awaitingGameSnapshot;
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

  Future<void> completeInitialSetup({required List<int> board}) async {
    final result = await _request('game:setup-complete', {'board': board});
    _setGameSnapshot(Map<String, dynamic>.from(result['state'] as Map));
  }

  Future<void> leaveRoom() async {
    final hadActiveRoom = room != null && !_hasLeftRoom;
    _hasLeftRoom = true;
    room = null;
    game = null;
    playerId = null;
    _myBoard = null;
    _isRestoringRoom = false;
    _roomRestored = true;
    _awaitingGameSnapshot = false;
    lastError = null;
    notifyListeners();

    if (hadActiveRoom && _socket.connected) {
      try {
        await _request('lobby:leave', const {});
      } catch (_) {
        // Ignorar si la sala ya fue cerrada o la conexión cambió.
      }
    }
  }

  @override
  void dispose() {
    if (room != null && !_hasLeftRoom && _socket.connected) {
      _hasLeftRoom = true;
      _socket.emit('lobby:leave', const <String, dynamic>{});
    }
    room = null;
    game = null;
    playerId = null;
    _myBoard = null;
    _socket.dispose();
    socket_io.cache.clear();
    super.dispose();
  }
}
