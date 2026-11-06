import 'package:flutter/material.dart';

import 'brilliantravensburger.dart';
import 'juego_screen.dart';
import 'multiplayer_service.dart';
import 'tablero_preview.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    required this.token,
    required this.username,
    this.joinMode = false,
  });

  final String token;
  final String username;
  final bool joinMode;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _codeController = TextEditingController();
  MultiplayerService? _service;
  int _capacity = 2;
  int _boardId = 1;
  bool _loading = false;
  bool _didNavigateToGame = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _service?.removeListener(_onServiceUpdate);
    super.dispose();
  }

  Future<MultiplayerService> _getService() async {
    if (_service != null) return _service!;
    final service = await MultiplayerService.connect(token: widget.token);
    service.addListener(_onServiceUpdate);
    _service = service;
    return service;
  }

  Future<void> _runRoomAction(
    Future<void> Function(MultiplayerService service) action,
  ) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = await _getService();
      await action(service);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createRoom() {
    final board = crearTablero(_boardId);
    final points = board.zonas.map((zone) => zone.bolsaPuntos).toList();
    return _runRoomAction(
      (service) => service.createRoom(
        capacity: _capacity,
        boardId: _boardId,
        zonePointValues: points,
      ),
    );
  }

  Future<void> _joinRoom() {
    return _runRoomAction((service) => service.joinRoom(_codeController.text));
  }

  void _onServiceUpdate() {
    final service = _service;
    if (!mounted || service == null) return;
    if (_didNavigateToGame) return;
    if (service.game == null || service.room?.status != 'playing') {
      setState(() {});
      return;
    }

    _didNavigateToGame = true;
    final room = service.room!;
    final board = crearTablero(room.boardId);
    final previousBoard = service.myBoard;
    if (previousBoard != null && previousBoard.length == 49) {
      for (var index = 0; index < previousBoard.length; index++) {
        board.celdas[index ~/ 7][index % 7] = previousBoard[index];
      }
    } else {
      final positions = obtenerPosicionesInicialesTablero(room.boardId);
      for (var index = 0; index < positions.length; index++) {
        board.celdas[positions[index][0]][positions[index][1]] = index + 1;
      }
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => JuegoScreen(
          tablero: board,
          tableroSeleccionado: room.boardId,
          multiplayer: service,
        ),
      ),
    );
  }

  Future<void> _toggleReady(MultiplayerPlayer player) async {
    await _runRoomAction((service) => service.setReady(!player.ready));
  }

  Future<void> _changeBoard(MultiplayerService service, int boardId) async {
    if (boardId == service.room?.boardId ||
        service.playerId != service.room?.hostId) {
      return;
    }
    final board = crearTablero(boardId);
    final points = board.zonas.map((zone) => zone.bolsaPuntos).toList();
    await _runRoomAction(
      (service) => service.setBoard(
        boardId: boardId,
        zonePointValues: points,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    final room = service?.room;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.joinMode ? 'Unirse a sala' : 'Crear sala'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: room == null
              ? _buildRoomOptions()
              : _buildRoom(room, service!),
        ),
      ),
    );
  }

  Widget _buildRoomOptions() {
    return ListView(
      children: [
        const Icon(Icons.groups_outlined, size: 64, color: Colors.blue),
        const SizedBox(height: 12),
        Text(
          'Hola, ${widget.username}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.joinMode
              ? 'Ingresa el código de la sala para unirte a la partida.'
              : 'Configura tu sala. La partida comienza cuando esté completa y todos estén listos.',
          textAlign: TextAlign.center,
        ),
        if (!widget.joinMode) ...[
          const SizedBox(height: 24),
          DropdownButtonFormField<int>(
            key: ValueKey(_capacity),
            initialValue: _capacity,
            decoration: const InputDecoration(
              labelText: 'Cantidad de jugadores',
              border: OutlineInputBorder(),
            ),
            items: List.generate(
              5,
              (index) => DropdownMenuItem(
                value: index + 2,
                child: Text('${index + 2} jugadores'),
              ),
            ),
            onChanged: _loading
                ? null
                : (value) => setState(() => _capacity = value ?? 2),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey(_boardId),
            initialValue: _boardId,
            decoration: const InputDecoration(
              labelText: 'Tablero compartido',
              border: OutlineInputBorder(),
            ),
            items: List.generate(
              4,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('Tablero ${index + 1}'),
              ),
            ),
            onChanged: _loading
                ? null
                : (value) => setState(() => _boardId = value ?? 1),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _createRoom,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Crear sala'),
            ),
          ),
        ] else ...[
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Código de sala',
              hintText: 'Ej. A1B2C3',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _joinRoom,
              icon: const Icon(Icons.login),
              label: const Text('Unirme a una sala'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null) _errorMessage(_error!),
      ],
    );
  }

  Widget _buildRoom(MultiplayerRoom room, MultiplayerService service) {
    MultiplayerPlayer? me;
    for (final player in room.players) {
      if (player.id == service.playerId) {
        me = player;
        break;
      }
    }
    final currentPlayer = me;
    final isFull = room.players.length == room.capacity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.meeting_room_outlined, size: 54, color: Colors.blue),
        const SizedBox(height: 8),
        const Text(
          'Comparte este código',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        SelectableText(
          room.code,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tablero ${room.boardId} · ${room.capacity} jugadores · objetivo ${room.targetPoints} pts',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          service.playerId == room.hostId
              ? 'Elige el tablero para todos'
              : 'Tablero elegido por el anfitrión',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.1,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              final boardId = index + 1;
              final isSelected = room.boardId == boardId;
              final canSelect =
                  service.playerId == room.hostId &&
                  room.status == 'waiting' &&
                  !_loading;
              return Card(
                margin: EdgeInsets.zero,
                color: isSelected ? Colors.blue.shade50 : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Colors.blue : Colors.black12,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('room-board-$boardId'),
                  onTap: canSelect
                      ? () => _changeBoard(service, boardId)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        TableroPreview(boardId: boardId, size: 48),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isSelected
                                ? 'Tablero $boardId\nEn uso'
                                : 'Tablero $boardId',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.blue.shade900 : null,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Jugadores (${room.players.length}/${room.capacity})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              for (final player in room.players)
                Card(
                  child: ListTile(
                    leading: Icon(
                      player.ready ? Icons.check_circle : Icons.hourglass_empty,
                      color: player.ready ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      '${player.username}${player.id == room.hostId ? ' (anfitrión)' : ''}',
                    ),
                    subtitle: Text(
                      player.ready ? 'Listo' : 'Esperando confirmación',
                    ),
                    trailing: player.connected
                        ? null
                        : const Icon(Icons.wifi_off, color: Colors.red),
                  ),
                ),
              if (!isFull)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Esperando ${room.capacity - room.players.length} jugador(es) más…',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        if (_error != null) _errorMessage(_error!),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Center(child: CircularProgressIndicator()),
          ),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _loading || currentPlayer == null
                ? null
                : () => _toggleReady(currentPlayer),
            icon: Icon(me?.ready == true ? Icons.undo : Icons.check_circle),
            label: Text(me?.ready == true ? 'Cancelar listo' : 'Estoy listo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: me?.ready == true ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        TextButton(
          onPressed: _loading
              ? null
              : () => _runRoomAction((service) => service.leaveRoom()),
          child: const Text('Salir de la sala'),
        ),
      ],
    );
  }

  Widget _errorMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
