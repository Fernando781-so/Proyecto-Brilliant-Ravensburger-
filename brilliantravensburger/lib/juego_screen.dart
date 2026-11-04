import 'dart:math';
import 'package:flutter/material.dart';
import 'brilliantravensburger.dart';

class JuegoScreen extends StatefulWidget {
  final Tablero tablero;
  final int? tableroSeleccionado;

  const JuegoScreen({
    super.key,
    required this.tablero,
    this.tableroSeleccionado,
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
  List<int>? _casillaJugada;

  final Random _random = Random();

  int get numeroAncla => anclaSeleccionada == 1 ? dado1 : dado2;
  int get numeroColocar => anclaSeleccionada == 1 ? dado2 : dado1;

  List<List<int>> get posicionesValidas {
    if (_casillaJugada != null) return [];
    return obtenerPosicionesValidas(widget.tablero, numeroAncla, numeroColocar);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.tablero.estaCompleto) {
        _finalizarPartida();
      } else {
        _lanzarDadosAutomatico();
      }
    });
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

  void _deshacerJugada() {
    final casilla = _casillaJugada;
    if (casilla == null || partidaFinalizada) return;

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
    if (partidaFinalizada || _casillaJugada != null) return;

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
    int puntaje = widget.tablero.calcularPuntajeTotal();

    return Scaffold(
      appBar: AppBar(
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
                  const Text(
                    '🎲 Dados de la mesa (Lanzamiento Automático):',
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
                          if (_casillaJugada == null) {
                            setState(() => anclaSeleccionada = 1);
                          }
                        },
                      ),
                      ElevatedButton.icon(
                        onPressed: _casillaJugada != null
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      _buildDadoWidget(
                        valor: dado2,
                        esAncla: anclaSeleccionada == 2,
                        onTap: () {
                          if (_casillaJugada == null) {
                            setState(() => anclaSeleccionada = 2);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                        onPressed: _casillaJugada == null || partidaFinalizada
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
                            : _casillaJugada == null
                            ? _confirmarSaltarTurno
                            : _siguienteTurno,
                        icon: Icon(
                          _casillaJugada == null
                              ? Icons.skip_next
                              : Icons.arrow_forward,
                        ),
                        label: Text(
                          _casillaJugada == null
                              ? 'SALTAR TURNO'
                              : 'AVANZAR TURNO',
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
