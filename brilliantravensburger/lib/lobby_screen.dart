import 'dart:async';

import 'package:flutter/material.dart';
import 'app_background.dart';
import 'audio_service.dart';
import 'brilliantravensburger.dart';
import 'inicio_screen.dart';
import 'modos_juego_info.dart';
import 'multiplayer_service.dart';
import 'tablero_preview.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    required this.token,
    required this.username,
    this.joinMode = false,
    this.service,
  });

  final String token;
  final String username;
  final bool joinMode;
  final MultiplayerService? service;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _codeController = TextEditingController();
  final ScrollController _boardsScrollController = ScrollController();
  MultiplayerService? _service;
  int _capacity = 2;
  int _boardId = 1;
  bool _isRanked = false;
  bool _timeTrial = false;
  bool _loading = false;
  bool _didNavigateToGame = false;
  bool _allowExit = false;
  bool _exitRequested = false;
  bool _leavingRoom = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(AudioService.instance.reproducirMusicaMenu());
    if (widget.service != null) {
      _service = widget.service;
      _service!.addListener(_onServiceUpdate);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _boardsScrollController.dispose();
    _service?.removeListener(_onServiceUpdate);
    if (!_didNavigateToGame) _service?.dispose();
    super.dispose();
  }

  Future<MultiplayerService> _getService() async {
    if (_service != null && _service!.isConnected) return _service!;
    if (_service != null && widget.service == null) {
      _service!.removeListener(_onServiceUpdate);
      _service!.dispose();
      _service = null;
    } else if (_service != null) {
      return _service!;
    }
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
      if (_exitRequested && service.room != null) {
        await service.leaveRoom();
      }
    } catch (error) {
      if (_service != null &&
          !_service!.isConnected &&
          widget.service == null) {
        _service!.removeListener(_onServiceUpdate);
        _service!.dispose();
        _service = null;
      }
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (_exitRequested) {
          _exitRequested = false;
          await _handleLobbyExit();
        }
      }
    }
  }

  Future<void> _handleLobbyExit() async {
    if (_allowExit || _leavingRoom) return;
    if (_loading) {
      _exitRequested = true;
      return;
    }

    final service = _service;
    if (service?.room != null) {
      setState(() => _leavingRoom = true);
      try {
        await service!.leaveRoom();
      } catch (error) {
        if (mounted) {
          setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''),
          );
        }
      } finally {
        if (mounted) setState(() => _leavingRoom = false);
      }
    }

    if (!mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  Future<void> _createRoom() {
    unawaited(AudioService.instance.reproducirSelect());
    final board = crearTablero(_boardId);
    final points = board.zonas.map((zone) => zone.bolsaPuntos).toList();
    return _runRoomAction(
      (service) => service.createRoom(
        capacity: _capacity,
        boardId: _boardId,
        zonePointValues: points,
        ranked: _isRanked,
        timeTrial: _timeTrial,
      ),
    );
  }

  Future<void> _joinRoom() {
    unawaited(AudioService.instance.reproducirSelect());
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            InicioScreen(tableroInicial: room.boardId, multiplayer: service),
      ),
    );
  }

  Future<void> _toggleReady(MultiplayerPlayer player) async {
    if (player.ready) {
      unawaited(AudioService.instance.reproducirBack());
    } else {
      unawaited(AudioService.instance.reproducirSelect());
    }
    await _runRoomAction((service) => service.setReady(!player.ready));
  }

  Future<void> _changeBoard(MultiplayerService service, int boardId) async {
    if (boardId == service.room?.boardId ||
        service.playerId != service.room?.hostId) {
      return;
    }
    unawaited(AudioService.instance.reproducirSelect());
    final board = crearTablero(boardId);
    final points = board.zonas.map((zone) => zone.bolsaPuntos).toList();
    await _runRoomAction(
      (service) => service.setBoard(boardId: boardId, zonePointValues: points),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    final room = service?.room;

    return PopScope<Object?>(
      canPop: _allowExit || (room == null && !_loading && !_leavingRoom),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(AudioService.instance.reproducirBack());
          _handleLobbyExit();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.joinMode ? 'Unirse a sala' : 'Crear sala'),
          centerTitle: true,
          actions: const [AudioSettingsButton()],
        ),
        body: AppBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: room == null
                  ? _buildRoomOptions()
                  : _buildRoom(room, service!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomOptions() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final bordeInactivo = esOscuro ? Colors.white24 : Colors.black12;
    final fondoRankedActivo = esOscuro
        ? const Color(0xFF4A3210)
        : Colors.amber.shade50;
    final bordeRankedActivo = esOscuro
        ? Colors.amber.shade300
        : Colors.amber.shade700;
    final iconoRankedActivo = esOscuro
        ? Colors.amber.shade300
        : Colors.amber.shade800;
    final fondoContraRelojActivo = esOscuro
        ? const Color(0xFF4A2511)
        : Colors.deepOrange.shade50;
    final bordeContraRelojActivo = esOscuro
        ? Colors.deepOrange.shade300
        : Colors.deepOrange.shade600;
    final iconoContraRelojActivo = esOscuro
        ? Colors.deepOrange.shade300
        : Colors.deepOrange.shade700;
    final fondoTableroSeleccionado = esOscuro
        ? const Color(0xFF16324F)
        : Colors.blue.shade50;
    final textoTableroSeleccionado = esOscuro
        ? Colors.lightBlue.shade100
        : Colors.blue.shade900;

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
                : (value) {
                    unawaited(AudioService.instance.reproducirSelect());
                    setState(() => _capacity = value ?? 2);
                  },
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            key: const ValueKey('ranked-mode-switch'),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _isRanked ? bordeRankedActivo : bordeInactivo,
                width: _isRanked ? 2 : 1,
              ),
            ),
            tileColor: _isRanked ? fondoRankedActivo : null,
            secondary: Icon(
              _isRanked ? Icons.emoji_events : Icons.sports_esports_outlined,
              color: _isRanked ? iconoRankedActivo : Colors.blueGrey,
            ),
            title: Text(
              _isRanked ? 'Modo Clasificatoria (Ranked)' : 'Modo Casual',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _isRanked
                  ? 'Compite por rangos: ganas o pierdes puntos según tu posición y el nivel de tus rivales.'
                  : 'Partida amistosa sin cambios en puntos de clasificatoria.',
              style: const TextStyle(fontSize: 12),
            ),
            value: _isRanked,
            onChanged: _loading
                ? null
                : (value) {
                    unawaited(AudioService.instance.reproducirSelect());
                    setState(() => _isRanked = value);
                  },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const ValueKey('time-trial-mode-switch'),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _timeTrial ? bordeContraRelojActivo : bordeInactivo,
                width: _timeTrial ? 2 : 1,
              ),
            ),
            tileColor: _timeTrial ? fondoContraRelojActivo : null,
            secondary: Icon(
              _timeTrial ? Icons.timer : Icons.timer_off_outlined,
              color: _timeTrial ? iconoContraRelojActivo : Colors.blueGrey,
            ),
            title: const Text(
              'Contra reloj',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _timeTrial
                  ? '5 min para números iniciales y 2 min por turno.'
                  : 'Sin límite de tiempo por turno.',
              style: const TextStyle(fontSize: 12),
            ),
            value: _timeTrial,
            onChanged: _loading
                ? null
                : (value) {
                    unawaited(AudioService.instance.reproducirSelect());
                    setState(() => _timeTrial = value);
                  },
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey('lobby-modes-info-button'),
              onPressed: () => mostrarReglasModosJuego(context),
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('Ver reglas y modos de juego'),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecciona el tablero',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: Scrollbar(
              controller: _boardsScrollController,
              thumbVisibility: true,
              child: ListView(
                key: const ValueKey('creation-boards-list'),
                controller: _boardsScrollController,
                children: [
                  for (var index = 0; index < 4; index++)
                    Builder(
                      builder: (context) {
                        final boardId = index + 1;
                        final isSelected = _boardId == boardId;
                        return Card(
                          key: ValueKey('creation-board-card-$boardId'),
                          margin: const EdgeInsets.only(right: 12, bottom: 8),
                          color: isSelected ? fondoTableroSeleccionado : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? Colors.blue : bordeInactivo,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: ValueKey('creation-board-$boardId'),
                            onTap: _loading
                                ? null
                                : () {
                                    unawaited(
                                      AudioService.instance.reproducirSelect(),
                                    );
                                    setState(() => _boardId = boardId);
                                  },
                            child: SizedBox(
                              height: 76,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Row(
                                  children: [
                                    TableroPreview(boardId: boardId, size: 62),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        isSelected
                                            ? 'Tablero $boardId · Seleccionado'
                                            : 'Tablero $boardId',
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? textoTableroSeleccionado
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              key: const ValueKey('create-room-button'),
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
        const Icon(Icons.meeting_room_outlined, size: 40, color: Colors.blue),
        const SizedBox(height: 4),
        const Text(
          'Comparte este código',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        SelectableText(
          room.code,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tablero ${room.boardId} · ${room.capacity} jugadores · objetivo ${room.targetPoints} pts',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              Container(
                key: const ValueKey('room-mode-badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: room.ranked
                      ? Colors.amber.shade100
                      : Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: room.ranked
                        ? Colors.amber.shade700
                        : Colors.blueGrey.shade200,
                  ),
                ),
                child: Text(
                  room.ranked ? 'Modo Clasificatoria (Ranked)' : 'Modo Casual',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: room.ranked
                        ? Colors.amber.shade900
                        : Colors.blueGrey.shade800,
                  ),
                ),
              ),
              if (room.timeTrial)
                Container(
                  key: const ValueKey('room-time-trial-badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepOrange.shade400),
                  ),
                  child: Text(
                    '⏱ Contra reloj (2 min)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade900,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (room.ranked && hayCompensacionRankedEnSala(room.players)) ...[
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              final esOscuro = Theme.of(context).brightness == Brightness.dark;
              return Container(
                key: const ValueKey('ranked-compensation-banner'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: esOscuro
                      ? const Color(0xFF4A3210)
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: esOscuro
                        ? Colors.amber.shade300
                        : Colors.amber.shade700,
                  ),
                ),
                child: Text(
                  '⚖️ Compensación activa por diferencia de nivel: pérdida reducida (50% o 0 pts) y +20% extra al vencer a rivales superiores.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: esOscuro
                        ? Colors.amber.shade100
                        : Colors.amber.shade900,
                  ),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 6),
        Text(
          service.playerId == room.hostId
              ? 'Elige el tablero para todos'
              : 'Tablero elegido por el anfitrión',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;
            final crossAxisCount = isWide ? 4 : 2;
            final rowExtent = isWide ? 66.0 : 58.0;
            final gridHeight = isWide ? rowExtent : (rowExtent * 2) + 8;
            return SizedBox(
              height: gridHeight,
              child: GridView.builder(
                key: const ValueKey('room-boards-grid'),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: rowExtent,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final boardId = index + 1;
                  final isSelected = room.boardId == boardId;
                  final canSelect =
                      service.playerId == room.hostId &&
                      room.status == 'waiting' &&
                      !_loading;
                  final esOscuro =
                      Theme.of(context).brightness == Brightness.dark;
                  return Card(
                    margin: EdgeInsets.zero,
                    color: isSelected
                        ? (esOscuro
                              ? const Color(0xFF16324F)
                              : Colors.blue.shade50)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.blue
                            : (esOscuro ? Colors.white24 : Colors.black12),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            TableroPreview(boardId: boardId, size: 44),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isSelected
                                    ? 'Tablero $boardId\nEn uso'
                                    : 'Tablero $boardId',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? (esOscuro
                                            ? Colors.lightBlue.shade100
                                            : Colors.blue.shade900)
                                      : null,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Jugadores (${room.players.length}/${room.capacity})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            children: [
              for (final player in room.players)
                Card(
                  key: ValueKey('lobby-player-${player.id}'),
                  child: ListTile(
                    leading: Icon(
                      player.ready ? Icons.check_circle : Icons.hourglass_empty,
                      color: player.ready ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      '${player.username}${player.id == room.hostId ? ' (anfitrión)' : ''}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${player.rankedLevel} (${player.rankedPoints} pts)',
                          key: ValueKey('player-rank-${player.id}'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Text(
                          player.ready ? 'Listo' : 'Esperando confirmación',
                        ),
                      ],
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
              : () {
                  unawaited(AudioService.instance.reproducirBack());
                  _runRoomAction((service) => service.leaveRoom());
                },
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
