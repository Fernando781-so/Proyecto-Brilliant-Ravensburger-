import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'brilliantravensburger.dart';
import 'multiplayer_service.dart';

class JuegoScreen extends StatefulWidget {
  final Tablero tablero;
  final int? tableroSeleccionado;
  final MultiplayerService? multiplayer;

  const JuegoScreen({
    super.key,
    required this.tablero,
    this.tableroSeleccionado,
    this.multiplayer,
  });

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> {
  int dado1 = 1;
  int dado2 = 1;
  int anclaSeleccionada = 1;
  int turno = 1;
  bool partidaFinalizada = false;
  bool _esperandoDadosCompartidos = false;
  bool _dialogoFinalMostrado = false;
  bool _dialogoSalidaMostrado = false;
  bool _salidaConfirmada = false;
  int _ultimoTurnoCompartido = 0;
  List<int>? _casillaJugada;

  final Random _random = Random();

  int get numeroAncla => anclaSeleccionada == 1 ? dado1 : dado2;
  int get numeroColocar => anclaSeleccionada == 1 ? dado2 : dado1;
  bool get _requiereConfirmarSalida =>
      widget.multiplayer?.room?.status == 'playing' && !_salidaConfirmada;

  void _solicitarSalida() {
    unawaited(_confirmarSalida());
  }

  Future<void> _confirmarSalida() async {
    if (!_requiereConfirmarSalida || _dialogoSalidaMostrado) return;
    _dialogoSalidaMostrado = true;

    final salir = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        content: const Text(
          'Tienes 10 segundos para volver a conectarte. Si no regresas en ese plazo, quedarás fuera; el último jugador que permanezca conectado será el ganador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir jugando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir de todos modos'),
          ),
        ],
      ),
    );

    _dialogoSalidaMostrado = false;
    if (!mounted || salir != true) return;

    setState(() => _salidaConfirmada = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  List<List<int>> get posicionesValidas {
    if (_casillaJugada != null ||
        _esperandoDadosCompartidos ||
        widget.multiplayer?.canPlay == false ||
        widget.multiplayer?.myTurnIsComplete == true ||
        widget.multiplayer?.myBoardIsComplete == true) {
      return [];
    }
    return obtenerPosicionesValidas(widget.tablero, numeroAncla, numeroColocar);
  }

  @override
  void initState() {
    super.initState();
    final service = widget.multiplayer;
    if (service != null) {
      service.addListener(_onMultiplayerUpdate);
      final game = service.game;
      if (game != null) {
        dado1 = game.dice[0];
        dado2 = game.dice[1];
        turno = game.turn;
        _ultimoTurnoCompartido = game.turn;
        _esperandoDadosCompartidos =
            game.completedPlayerIds.contains(service.playerId) ||
            service.myBoardIsComplete;
        if (service.room?.status == 'finished') {
          partidaFinalizada = true;
          _dialogoFinalMostrado = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _mostrarResultadoMultijugador();
          });
        }
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.tablero.estaCompleto) {
        _finalizarPartida();
      } else {
        _lanzarDadosAutomatico();
      }
    });
  }

  @override
  void dispose() {
    final service = widget.multiplayer;
    if (service != null) {
      service.removeListener(_onMultiplayerUpdate);
      service.dispose();
    }
    super.dispose();
  }

  void _onMultiplayerUpdate() {
    final service = widget.multiplayer;
    final game = service?.game;
    if (!mounted || service == null || game == null) return;

    final nuevoTurno = game.turn != _ultimoTurnoCompartido;
    setState(() {
      turno = game.turn;
      dado1 = game.dice[0];
      dado2 = game.dice[1];
      partidaFinalizada = service.room?.status == 'finished';
      if (nuevoTurno) {
        _ultimoTurnoCompartido = game.turn;
        _casillaJugada = null;
        _esperandoDadosCompartidos = false;
        anclaSeleccionada =
            obtenerPosicionesValidas(widget.tablero, dado1, dado2).isNotEmpty
            ? 1
            : obtenerPosicionesValidas(widget.tablero, dado2, dado1).isNotEmpty
            ? 2
            : 1;
      } else if (service.myTurnIsComplete || service.myBoardIsComplete) {
        _esperandoDadosCompartidos = true;
      }
    });

    if (partidaFinalizada && !_dialogoFinalMostrado) {
      _dialogoFinalMostrado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostrarResultadoMultijugador();
      });
    } else if (nuevoTurno &&
        !partidaFinalizada &&
        !hayMovimientosPosibles(widget.tablero, dado1, dado2)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostrarAvisoSinMovimientos();
      });
    }
  }

  void _mostrarResultadoMultijugador() {
    final service = widget.multiplayer!;
    final room = service.room!;
    MultiplayerPlayer? winner;
    for (final player in room.players) {
      if (player.id == service.game?.winnerId) {
        winner = player;
        break;
      }
    }
    final ranking = [...room.players]
      ..sort((left, right) => right.score.compareTo(left.score));

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¡Partida finalizada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              winner == null
                  ? 'Ganador: ${ranking.first.username}'
                  : 'Ganador: ${winner.username}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            for (final player in ranking)
              Text('${player.username}: ${player.score} pts'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Ver tablero'),
          ),
        ],
      ),
    );
  }

  void _lanzarDadosAutomatico() {
    if (partidaFinalizada || widget.tablero.estaCompleto) {
      _finalizarPartida();
      return;
    }

    int d1 = _random.nextInt(6) + 1;
    int d2 = _random.nextInt(6) + 1;

    bool posible = hayMovimientosPosibles(widget.tablero, d1, d2);

    setState(() {
      dado1 = d1;
      dado2 = d2;

      if (obtenerPosicionesValidas(widget.tablero, d1, d2).isNotEmpty) {
        anclaSeleccionada = 1;
      } else if (obtenerPosicionesValidas(widget.tablero, d2, d1).isNotEmpty) {
        anclaSeleccionada = 2;
      } else {
        anclaSeleccionada = 1;
      }
    });

    if (!posible) {
      _mostrarAvisoSinMovimientos();
    }
  }

  void _mostrarAvisoSinMovimientos() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Sin movimientos'),
          ],
        ),
        content: Text(
          'Los dados de la mesa son [$dado1] y [$dado2]. No hay ninguna casilla válida disponible como ancla en este turno.\n\nSe pasará automáticamente al siguiente turno.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _siguienteTurno();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _confirmarSaltarTurno() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue, size: 28),
            SizedBox(width: 8),
            Text('¿Saltar turno?'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas saltar tu turno? Perderás la oportunidad de colocar un número en este turno.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _siguienteTurno();
            },
            child: const Text('Sí, saltar turno'),
          ),
        ],
      ),
    );
  }

  void _siguienteTurno() {
    if (partidaFinalizada) return;

    final service = widget.multiplayer;
    if (service != null) {
      if (!service.canPlay) return;
      _enviarTurnoMultijugador(service);
      return;
    }

    if (widget.tablero.estaCompleto) {
      _finalizarPartida();
      return;
    }

    setState(() {
      _casillaJugada = null;
      turno++;
    });
    _lanzarDadosAutomatico();
  }

  Future<void> _enviarTurnoMultijugador(MultiplayerService service) async {
    if (!service.canPlay ||
        _esperandoDadosCompartidos ||
        service.myTurnIsComplete) {
      return;
    }

    final claimedZones = <int>[];
    final zoneClaims = service.game?.zoneClaims ?? const {};
    for (var index = 0; index < widget.tablero.zonas.length; index++) {
      final zone = widget.tablero.zonas[index];
      final priorClaims = zoneClaims[index] ?? const [];
      final alreadyClaimed = priorClaims.any(
        (claim) => '${claim['playerId']}' == service.playerId,
      );
      if (!alreadyClaimed && zone.esValida(widget.tablero)) {
        claimedZones.add(index);
      }
    }

    setState(() => _esperandoDadosCompartidos = true);
    try {
      await service.completeTurn(
        board: widget.tablero.celdas.expand((row) => row).toList(),
        completedZones: claimedZones,
        finished: widget.tablero.estaCompleto,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _esperandoDadosCompartidos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo enviar el turno: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _deshacerJugada() {
    final casilla = _casillaJugada;
    if (casilla == null ||
        partidaFinalizada ||
        widget.multiplayer?.canPlay == false) {
      return;
    }

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    setState(() {
      widget.tablero.celdas[casilla[0]][casilla[1]] = 0;
      _casillaJugada = null;
    });
  }

  void _finalizarPartida() {
    if (partidaFinalizada || !widget.tablero.estaCompleto) return;

    setState(() {
      partidaFinalizada = true;
    });

    final puntajeTotal = widget.tablero.calcularPuntajeTotal();
    final resumenPuntos = widget.tablero.obtenerResumenPuntos();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('¡Partida finalizada!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Puntaje total: $puntajeTotal pts',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final region in Region.values.where(resumenPuntos.containsKey))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${_nombreRegion(region)}: ${resumenPuntos[region] ?? 0} pts',
                ),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Ver tablero'),
          ),
        ],
      ),
    );
  }

  String _nombreRegion(Region region) {
    switch (region) {
      case Region.amarillo:
        return 'Amarillo';
      case Region.verde:
        return 'Verde';
      case Region.azul:
        return 'Azul';
      case Region.lila:
        return 'Lila';
      case Region.rojo:
        return 'Rojo';
      case Region.blanco:
        return 'Blanco';
      case Region.naranja:
        return 'Naranja';
    }
  }

  String _nombreZonaRegla(Zona zona) {
    if (zona.region == Region.naranja) {
      if (zona.valorMinimo == 4 && zona.valorMaximo == 6) {
        return 'Anaranjado superior';
      }
      if (zona.valorMinimo == 1 && zona.valorMaximo == 3) {
        return 'Anaranjado inferior';
      }
    }
    return _nombreRegion(zona.region);
  }

  String _descripcionRegla(Zona zona) {
    switch (zona.region) {
      case Region.amarillo:
        return 'Máximo 5 números por zona.';
      case Region.verde:
        return 'Se puede colocar cualquier número.';
      case Region.azul:
      case Region.blanco:
        return 'Todos los números de la zona deben ser iguales.';
      case Region.lila:
        return 'Se permiten como máximo 2 números distintos.';
      case Region.rojo:
        return 'No se puede repetir ningún número.';
      case Region.naranja:
        if (zona.valorMinimo != null && zona.valorMaximo != null) {
          return 'Solo se permiten números del ${zona.valorMinimo} al ${zona.valorMaximo}.';
        }
        return 'Esta zona no tiene un rango de números definido.';
    }
  }

  Widget _buildZoneInfoTile(
    int index,
    Zona zona,
    Map<int, List<Map<String, dynamic>>> claimsByZone,
  ) {
    final claims = claimsByZone[index] ?? const [];
    Map<String, dynamic>? claimForPlayer;
    final playerId = widget.multiplayer?.playerId;
    if (playerId != null) {
      for (final claim in claims) {
        if ('${claim['playerId']}' == playerId) {
          claimForPlayer = claim;
          break;
        }
      }
    }

    final points = zona.bolsaPuntos;
    final nextPointIndex = points.isEmpty
        ? 0
        : min(claims.length, points.length - 1);
    final nextPoints = points.isEmpty ? 0 : points[nextPointIndex];
    final claimedPoints = (claimForPlayer?['points'] as num?)?.toInt();

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Tooltip(
        message: _descripcionRegla(zona),
        triggerMode: TooltipTriggerMode.tap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _colorParaRegion(zona.region),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black38),
          ),
          child: const Icon(
            Icons.info_outline,
            size: 18,
            color: Colors.black87,
          ),
        ),
      ),
      title: Text('Zona ${index + 1} · ${_nombreZonaRegla(zona)}'),
      subtitle: Text(
        'Puntos: ${points.join(' → ')}',
        key: ValueKey('zone-points-${index + 1}'),
      ),
      trailing: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              claimedPoints == null ? 'Próximo' : 'Reclamada',
              style: const TextStyle(fontSize: 11),
            ),
            Text(
              claimedPoints == null
                  ? '+$nextPoints pts'
                  : '+$claimedPoints pts',
              style: const TextStyle(fontWeight: FontWeight.bold),
              key: ValueKey('zone-next-points-${index + 1}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesDropdown() {
    final zonas = widget.tablero.zonas;
    final claimsByZone = widget.multiplayer?.game?.zoneClaims ?? const {};
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.hearing),
        title: const Text('Reglas y puntos por zona'),
        subtitle: Text('${zonas.length} zonas · toca el color para la regla'),
        children: [
          if (zonas.isEmpty)
            const ListTile(
              dense: true,
              title: Text('Este tablero no tiene zonas.'),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var index = 0; index < zonas.length; index++) ...[
                      if (index > 0) const Divider(height: 1),
                      _buildZoneInfoTile(index, zonas[index], claimsByZone),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _rankLabel(int index) {
    switch (index) {
      case 0:
        return '1.er lugar';
      case 1:
        return '2.º lugar';
      case 2:
        return '3.er lugar';
      default:
        return '${index + 1}.º lugar';
    }
  }

  Color _rankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber.shade100;
      case 1:
        return Colors.blueGrey.shade100;
      case 2:
        return Colors.brown.shade100;
      default:
        return Colors.blueGrey.shade50;
    }
  }

  Widget _buildMatchInfoDropdown(MultiplayerService service) {
    final room = service.room;
    if (room == null) return const SizedBox.shrink();

    final players = room.players.where((player) => player.connected).toList()
      ..sort((left, right) {
        final scoreComparison = right.score.compareTo(left.score);
        return scoreComparison != 0
            ? scoreComparison
            : left.username.compareTo(right.username);
      });
    final claimsByZone = service.game?.zoneClaims ?? const {};
    final claimedZones =
        claimsByZone.entries
            .where(
              (entry) =>
                  entry.value.isNotEmpty &&
                  entry.key >= 0 &&
                  entry.key < widget.tablero.zonas.length,
            )
            .toList()
          ..sort((left, right) => left.key.compareTo(right.key));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.leaderboard_outlined),
        title: const Text('Jugadores conectados y zonas capturadas'),
        subtitle: Text(
          '${players.length} conectados · ${claimedZones.length} zonas · Meta: ${room.targetPoints} pts',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Puntaje de jugadores conectados',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (players.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('No hay jugadores conectados.'),
                    )
                  else
                    for (var index = 0; index < players.length; index++)
                      ListTile(
                        key: ValueKey('connected-player-${players[index].id}'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: _rankColor(index),
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          players[index].username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_rankLabel(index)),
                        trailing: Text(
                          '${players[index].score} pts',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  const Divider(height: 20),
                  Text(
                    'Zonas capturadas (${claimedZones.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (claimedZones.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Todavía no se ha capturado ninguna zona.'),
                    )
                  else
                    for (final entry in claimedZones) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Zona ${entry.key + 1} · ${_nombreRegion(widget.tablero.zonas[entry.key].region)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      for (
                        var claimIndex = 0;
                        claimIndex < entry.value.length;
                        claimIndex++
                      )
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 42,
                                child: Text(
                                  claimIndex == 0
                                      ? '1.º'
                                      : claimIndex == 1
                                      ? '2.º'
                                      : '3.º+',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${entry.value[claimIndex]['username'] ?? 'Jugador'}',
                                ),
                              ),
                              Text(
                                '+${((entry.value[claimIndex]['points'] ?? entry.value[claimIndex]['score']) as num?)?.toInt() ?? 0} pts',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mensajeCasilla(int fila, int columna, bool esValida) {
    if (esValida) {
      return 'Puedes colocar el número $numeroColocar aquí.';
    }

    final valorActual = widget.tablero.celdas[fila][columna];
    if (valorActual != 0) {
      return 'No puedes colocar el número $numeroColocar aquí porque la casilla ya contiene el número $valorActual.';
    }

    final esAdyacenteAlAncla =
        [
          [fila - 1, columna],
          [fila + 1, columna],
          [fila, columna - 1],
          [fila, columna + 1],
        ].any(
          (posicion) =>
              posicion[0] >= 0 &&
              posicion[0] < 7 &&
              posicion[1] >= 0 &&
              posicion[1] < 7 &&
              widget.tablero.celdas[posicion[0]][posicion[1]] == numeroAncla,
        );
    if (!esAdyacenteAlAncla) {
      return 'No puedes colocar el número $numeroColocar aquí porque la casilla no está junto al ancla $numeroAncla.';
    }

    Zona? zonaActual;
    for (final zona in widget.tablero.zonas) {
      if (zona.posiciones.any(
        (posicion) => posicion[0] == fila && posicion[1] == columna,
      )) {
        zonaActual = zona;
        break;
      }
    }
    if (zonaActual == null) {
      return 'No puedes colocar el número $numeroColocar aquí porque la casilla no pertenece a una región válida.';
    }

    final valoresExistentes = zonaActual.posiciones
        .where((posicion) => posicion[0] != fila || posicion[1] != columna)
        .map((posicion) => widget.tablero.celdas[posicion[0]][posicion[1]])
        .where((valor) => valor != 0)
        .toList();

    switch (zonaActual.region) {
      case Region.azul:
        return 'No puedes colocar el número $numeroColocar aquí porque la región azul requiere números iguales${valoresExistentes.isEmpty ? '' : ' (ya hay ${valoresExistentes.join(', ')}).'}';
      case Region.lila:
        return 'No puedes colocar el número $numeroColocar aquí porque la región lila permite como máximo dos números distintos.';
      case Region.rojo:
        return 'No puedes colocar el número $numeroColocar aquí porque la región roja no permite repetir números.';
      case Region.blanco:
        return 'No puedes colocar el número $numeroColocar aquí porque la región blanca requiere números iguales${valoresExistentes.isEmpty ? '' : ' (ya hay ${valoresExistentes.join(', ')}).'}';
      case Region.naranja:
        if (zonaActual.valorMinimo != null && zonaActual.valorMaximo != null) {
          return 'No puedes colocar el número $numeroColocar aquí porque la región naranja solo permite números del ${zonaActual.valorMinimo} al ${zonaActual.valorMaximo}.';
        }
        return 'No puedes colocar el número $numeroColocar aquí porque la región naranja no tiene un rango válido.';
      case Region.amarillo:
        return 'No puedes colocar el número $numeroColocar aquí porque la región amarilla ya tiene el máximo de casillas permitidas.';
      case Region.verde:
        return 'No puedes colocar el número $numeroColocar aquí porque la regla de la región verde no permite esta jugada.';
    }
  }

  // Al seleccionar una casilla del tablero
  void _alTocarCasilla(int fila, int columna) {
    if (partidaFinalizada ||
        _casillaJugada != null ||
        widget.multiplayer?.canPlay == false) {
      return;
    }

    bool esValida = posicionesValidas.any(
      (p) => p[0] == fila && p[1] == columna,
    );

    if (!esValida) return;

    setState(() {
      widget.tablero.celdas[fila][columna] = numeroColocar;
      _casillaJugada = [fila, columna];
    });
  }

  Region _obtenerRegionCasilla(int fila, int columna) {
    for (var zona in widget.tablero.zonas) {
      if (zona.posiciones.any((p) => p[0] == fila && p[1] == columna)) {
        return zona.region;
      }
    }
    return Region.verde;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_requiereConfirmarSalida,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _requiereConfirmarSalida) {
          _solicitarSalida();
        }
      },
      child: _buildGameScaffold(),
    );
  }

  Widget _buildGameScaffold() {
    final puntaje =
        widget.multiplayer?.myScore ?? widget.tablero.calcularPuntajeTotal();
    final service = widget.multiplayer;
    final esperandoConexion = service != null && !service.canPlay;
    final esperandoJugadores =
        _esperandoDadosCompartidos ||
        service?.myTurnIsComplete == true ||
        service?.myBoardIsComplete == true;

    return Scaffold(
      appBar: AppBar(
        leading: _requiereConfirmarSalida
            ? IconButton(
                tooltip: 'Salir de la partida',
                onPressed: _solicitarSalida,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Text(
          partidaFinalizada
              ? 'Partida finalizada'
              : widget.tableroSeleccionado == null
              ? 'Brilliant - Turno $turno'
              : 'Brilliant - Tablero ${widget.tableroSeleccionado} - Turno $turno',
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🏆 $puntaje pts',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (esperandoConexion)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      service.isConnected ? Icons.sync : Icons.wifi_off,
                      color: Colors.orange.shade900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        service.lastError == null
                            ? service.isConnected
                                  ? 'Conexión recuperada. Sincronizando la partida; tus puntos y turnos se conservan.'
                                  : 'Sin conexión. Reconectando; tus puntos y turnos se conservan.'
                            : 'No se pudo sincronizar la partida: ${service.lastError}',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (service.lastError != null)
                      TextButton.icon(
                        onPressed: service.isConnected
                            ? service.retryRoomRestore
                            : null,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    widget.multiplayer == null
                        ? '🎲 Dados de la mesa (Lanzamiento Automático):'
                        : '🎲 Dados compartidos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toca un dado o usa el botón para elegir el ANCLA:',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDadoWidget(
                        valor: dado1,
                        esAncla: anclaSeleccionada == 1,
                        onTap: () {
                          if (service?.canPlay != false &&
                              _casillaJugada == null) {
                            setState(() => anclaSeleccionada = 1);
                          }
                        },
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            service?.canPlay == false || _casillaJugada != null
                            ? null
                            : () {
                                setState(() {
                                  anclaSeleccionada = anclaSeleccionada == 1
                                      ? 2
                                      : 1;
                                });
                              },
                        icon: const Icon(Icons.swap_horiz, size: 20),
                        label: const Text('Cambiar Ancla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade900,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      _buildDadoWidget(
                        valor: dado2,
                        esAncla: anclaSeleccionada == 2,
                        onTap: () {
                          if (service?.canPlay != false &&
                              _casillaJugada == null) {
                            setState(() => anclaSeleccionada = 2);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildRulesDropdown(),
            if (widget.multiplayer != null)
              _buildMatchInfoDropdown(widget.multiplayer!),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Ancla: $numeroAncla ➔ Colocarás: $numeroColocar en una casilla iluminada',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            if (_casillaJugada != null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '¡Número Colocado!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                    itemCount: 49,
                    itemBuilder: (context, index) {
                      int fila = index ~/ 7;
                      int columna = index % 7;
                      int valor = widget.tablero.celdas[fila][columna];
                      Region region = _obtenerRegionCasilla(fila, columna);

                      bool esValida = posicionesValidas.any(
                        (p) => p[0] == fila && p[1] == columna,
                      );

                      return Tooltip(
                        key: ValueKey('casilla-juego-$fila-$columna'),
                        message: _mensajeCasilla(fila, columna, esValida),
                        preferBelow: false,
                        waitDuration: const Duration(milliseconds: 350),
                        child: MouseRegion(
                          cursor: esValida
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: () => _alTocarCasilla(fila, columna),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                color: esValida
                                    ? Colors.amber.shade300
                                    : _colorParaRegion(region),
                                border: Border.all(
                                  color: esValida
                                      ? Colors.amber.shade900
                                      : Colors.black26,
                                  width: esValida ? 3.5 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: esValida
                                    ? [
                                        BoxShadow(
                                          color: Colors.amber.withOpacity(0.6),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: esValida
                                    ? Text(
                                        '+$numeroColocar',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.amber.shade900,
                                        ),
                                      )
                                    : Text(
                                        valor == 0 ? '' : '$valor',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed:
                            _casillaJugada == null ||
                                partidaFinalizada ||
                                service?.canPlay == false
                            ? null
                            : _deshacerJugada,
                        icon: const Icon(Icons.undo),
                        label: const Text('Deshacer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(
                            color: Colors.red.shade300,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: partidaFinalizada
                            ? null
                            : esperandoConexion
                            ? null
                            : esperandoJugadores
                            ? null
                            : _casillaJugada == null
                            ? _confirmarSaltarTurno
                            : _siguienteTurno,
                        icon: Icon(
                          esperandoJugadores
                              ? Icons.hourglass_top
                              : _casillaJugada == null
                              ? Icons.skip_next
                              : Icons.arrow_forward,
                        ),
                        label: Text(
                          esperandoConexion
                              ? 'RECONECTANDO...'
                              : esperandoJugadores
                              ? 'ESPERANDO A LOS JUGADORES'
                              : _casillaJugada == null
                              ? 'SALTAR TURNO'
                              : 'Avanzar Turno',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _casillaJugada == null
                              ? Colors.orange.shade700
                              : Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDadoWidget({
    required int valor,
    required bool esAncla,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: esAncla ? Colors.blue.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: esAncla ? Colors.blue.shade900 : Colors.grey.shade400,
            width: esAncla ? 3.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$valor',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: esAncla ? Colors.white : Colors.black87,
              ),
            ),
            if (esAncla)
              const Text(
                'ANCLA',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _colorParaRegion(Region region) {
    switch (region) {
      case Region.amarillo:
        return Colors.amber.shade200;
      case Region.verde:
        return Colors.green.shade200;
      case Region.azul:
        return Colors.blue.shade200;
      case Region.lila:
        return Colors.purple.shade200;
      case Region.rojo:
        return Colors.red.shade200;
      case Region.blanco:
        return Colors.white;
      case Region.naranja:
        return Colors.orange.shade200;
    }
  }
}
