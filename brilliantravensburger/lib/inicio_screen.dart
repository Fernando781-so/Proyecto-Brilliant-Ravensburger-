import 'dart:async';

import 'package:flutter/material.dart';
import 'audio_service.dart';
import 'brilliantravensburger.dart';
import 'juego_screen.dart';
import 'multiplayer_service.dart';
import 'reglas_tablero_guide.dart';
import 'tablero_preview.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({
    super.key,
    this.tableroInicial,
    this.multiplayer,
    this.contraReloj = false,
  });

  final int? tableroInicial;
  final MultiplayerService? multiplayer;
  final bool contraReloj;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late Tablero tablero;
  late InicioBloc bloc;

  int? _tableroSeleccionado;
  List<int>? _posicionExplosion;
  bool _enviandoConfiguracion = false;
  bool _navegandoAlJuego = false;
  Timer? _setupTimer;
  int _segundosRestantesInicio = duracionInicioContraReloj.inSeconds;

  bool get _contraRelojActivo =>
      widget.contraReloj || (widget.multiplayer?.room?.timeTrial == true);

  @override
  void initState() {
    super.initState();
    final tableroId = widget.tableroInicial ?? 1;
    tablero = crearTablero(tableroId);
    bloc = InicioBloc(
      tablero: tablero,
      posicionesIniciales: obtenerPosicionesInicialesTablero(tableroId),
    );
    _tableroSeleccionado = widget.tableroInicial;

    final service = widget.multiplayer;
    if (service != null) {
      unawaited(
        AudioService.instance.reproducirMusicaPartida(
          clasificatoria: service.room?.ranked == true,
        ),
      );
      final savedBoard = service.myBoard;
      if (savedBoard != null && savedBoard.length == 49) {
        for (var index = 0; index < savedBoard.length; index++) {
          tablero.celdas[index ~/ 7][index % 7] = savedBoard[index];
        }
      }
      service.addListener(_onMultiplayerUpdate);
      if (_puedeAbrirPartidaMultijugador) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _abrirJuego());
      }
    }

    if (_contraRelojActivo &&
        _tableroSeleccionado != null &&
        !_puedeAbrirPartidaMultijugador) {
      _iniciarTemporizadorInicio();
    }
  }

  void _iniciarTemporizadorInicio() {
    _setupTimer?.cancel();
    _segundosRestantesInicio = duracionInicioContraReloj.inSeconds;
    _setupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_segundosRestantesInicio <= 1) {
        timer.cancel();
        setState(() => _segundosRestantesInicio = 0);
        _alVencerTiempoInicio();
      } else {
        setState(() => _segundosRestantesInicio--);
      }
    });
  }

  void _alVencerTiempoInicio() {
    if (!mounted || _navegandoAlJuego || _miConfiguracionCompletada) return;
    if (!bloc.puedeAvanzar) {
      final disponibles = [
        for (var n = 1; n <= 6; n++)
          if (!bloc.numeroYaUtilizado(n)) n,
      ];
      var indice = 0;
      setState(() {
        for (final pos in bloc.posicionesIniciales) {
          if (tablero.celdas[pos[0]][pos[1]] == 0 &&
              indice < disponibles.length) {
            bloc.colocarNumero(pos[0], pos[1], disponibles[indice++]);
          }
        }
      });
    }
    if (widget.multiplayer == null) {
      _abrirJuego();
    } else {
      unawaited(_confirmarConfiguracionInicial());
    }
  }

  @override
  void dispose() {
    _setupTimer?.cancel();
    final service = widget.multiplayer;
    service?.removeListener(_onMultiplayerUpdate);
    if (!_navegandoAlJuego) {
      service?.dispose();
    }
    super.dispose();
  }

  bool get _miConfiguracionCompletada =>
      widget.multiplayer?.mySetupIsComplete ?? false;

  bool get _puedeAbrirPartidaMultijugador {
    final service = widget.multiplayer;
    return service != null &&
        (service.room?.status == 'finished' ||
            (service.game?.phase == 'playing' && _miConfiguracionCompletada));
  }

  void _onMultiplayerUpdate() {
    if (!mounted) return;
    if (_puedeAbrirPartidaMultijugador) {
      _abrirJuego();
    } else {
      setState(() {});
    }
  }

  void _abrirJuego() {
    if (!mounted || _navegandoAlJuego) return;
    _navegandoAlJuego = true;
    _setupTimer?.cancel();
    final service = widget.multiplayer;
    if (service != null) {
      unawaited(
        AudioService.instance.reproducirMusicaPartida(
          clasificatoria: service.room?.ranked == true,
        ),
      );
      final savedBoard = service.myBoard;
      if (savedBoard != null && savedBoard.length == 49) {
        for (var index = 0; index < savedBoard.length; index++) {
          tablero.celdas[index ~/ 7][index % 7] = savedBoard[index];
        }
      }
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => JuegoScreen(
          tablero: tablero,
          tableroSeleccionado: _tableroSeleccionado,
          multiplayer: service,
          contraReloj: _contraRelojActivo,
        ),
      ),
    );
  }

  Future<void> _confirmarConfiguracionInicial() async {
    final service = widget.multiplayer;
    if (service == null ||
        !bloc.puedeAvanzar ||
        _miConfiguracionCompletada ||
        !service.canPlay ||
        _enviandoConfiguracion) {
      return;
    }

    setState(() => _enviandoConfiguracion = true);
    try {
      await service.completeInitialSetup(
        board: tablero.celdas.expand((row) => row).toList(),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo confirmar el tablero: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _enviandoConfiguracion = false);
    }
  }

  Widget _buildMultiplayerSetupStatus() {
    final service = widget.multiplayer!;
    final room = service.room;
    final players = room?.players ?? const <MultiplayerPlayer>[];
    final readyCount = room?.setupCompleteCount ?? 0;
    final disconnected = players
        .where((player) => !player.connected)
        .map((player) => player.username)
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              'Jugadores listos para jugar: $readyCount/${players.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_miConfiguracionCompletada)
              const Text('Tu tablero está listo; espera a los demás.')
            else if (service.game?.phase == 'playing')
              const Text(
                'Coloca tus 6 números iniciales para completar la configuración.',
              )
            else if (disconnected.isNotEmpty)
              Text(
                'Esperando que se reconecte${disconnected.length == 1 ? '' : 'n'}: ${disconnected.join(', ')}',
                textAlign: TextAlign.center,
              ),
            if (!service.canPlay)
              const Text('Sin conexión. Reconectando; tu tablero se conserva.'),
          ],
        ),
      ),
    );
  }

  Region _obtenerRegionCasilla(int fila, int columna) {
    return _obtenerRegionEnTablero(tablero, fila, columna);
  }

  Region _obtenerRegionEnTablero(Tablero tablero, int fila, int columna) {
    for (var zona in tablero.zonas) {
      if (zona.posiciones.any((p) => p[0] == fila && p[1] == columna)) {
        return zona.region;
      }
    }
    return Region.verde;
  }

  void _alTocarCasilla(int fila, int columna) {
    if (_miConfiguracionCompletada) return;
    if (!bloc.esPosicionInicial(fila, columna)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Toca una casilla con borde grueso para colocar un número.',
          ),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _mostrarMenuSeleccionNumero(fila, columna);
  }

  void _seleccionarTablero(int numero) {
    unawaited(AudioService.instance.reproducirSelect());
    setState(() {
      tablero = crearTablero(numero);
      bloc = InicioBloc(
        tablero: tablero,
        posicionesIniciales: obtenerPosicionesInicialesTablero(numero),
      );
      _posicionExplosion = null;
      _tableroSeleccionado = numero;
    });
    if (_contraRelojActivo) {
      _iniciarTemporizadorInicio();
    }
  }

  void _mostrarReglasDelTablero() {
    unawaited(AudioService.instance.reproducirSelect());
    final boardId = _tableroSeleccionado ?? 1;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reglas del tablero $boardId',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar reglas',
                      onPressed: () {
                        unawaited(AudioService.instance.reproducirBack());
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: ReglasTableroGuide(boardId: boardId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarMenuSeleccionNumero(int fila, int columna) {
    int valorActual = tablero.celdas[fila][columna];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            valorActual == 0
                ? 'Selecciona o mueve un número'
                : 'Modificar casilla (Actual: $valorActual)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Si el número ya está colocado, explotará de su casilla anterior y se moverá aquí:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(6, (i) {
                  int num = i + 1;
                  bool esElMismo = valorActual == num;
                  bool estaUsadoEnOtraParte =
                      bloc.numeroYaUtilizado(num) && !esElMismo;

                  return SizedBox(
                    width: 62,
                    height: 62,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: esElMismo
                            ? Colors.blue.shade600
                            : (estaUsadoEnOtraParte
                                  ? Colors.orange.shade50
                                  : Colors.blue.shade50),
                        foregroundColor: esElMismo
                            ? Colors.white
                            : (estaUsadoEnOtraParte
                                  ? Colors.orange.shade900
                                  : Colors.blue.shade900),
                        elevation: esElMismo ? 4 : 1,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: esElMismo
                                ? Colors.blue
                                : (estaUsadoEnOtraParte
                                      ? Colors.orange.shade300
                                      : Colors.blue.shade200),
                            width: esElMismo ? 2 : 1,
                          ),
                        ),
                      ),
                      onPressed: () {
                        List<int>? origenAnterior;

                        for (var pos in bloc.posicionesIniciales) {
                          int r = pos[0];
                          int c = pos[1];
                          if (tablero.celdas[r][c] == num &&
                              !(r == fila && c == columna)) {
                            origenAnterior = [r, c];
                            tablero.celdas[r][c] = 0;
                          }
                        }

                        setState(() {
                          tablero.celdas[fila][columna] = 0;
                          bloc.colocarNumero(fila, columna, num);

                          if (origenAnterior != null) {
                            _posicionExplosion = origenAnterior;
                          }
                        });

                        if (origenAnterior != null) {
                          unawaited(AudioService.instance.reproducirExplosion());
                        } else {
                          unawaited(
                            AudioService.instance.reproducirColocarNumero(),
                          );
                        }

                        Navigator.of(context).pop();

                        if (origenAnterior != null) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '💥 ¡El número $num cambió de casilla!',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.orange.shade800,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$num',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (estaUsadoEnOtraParte)
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(
                                Icons.swap_horiz,
                                size: 14,
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              if (valorActual != 0) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () {
                    unawaited(AudioService.instance.reproducirExplosion());
                    setState(() {
                      _posicionExplosion = [fila, columna];
                      tablero.celdas[fila][columna] = 0;
                    });
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Quitar número',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                unawaited(AudioService.instance.reproducirBack());
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool listo = bloc.puedeAvanzar;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tableroSeleccionado == null
              ? 'Brilliant - Elige tablero'
              : 'Brilliant - Posiciones Iniciales',
        ),
        centerTitle: true,
        elevation: 1,
        actions: [
          if (_contraRelojActivo && _tableroSeleccionado != null)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Center(
                child: Container(
                  key: const ValueKey('setup-timer-badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _segundosRestantesInicio <= 30
                        ? Colors.red.shade100
                        : Colors.deepOrange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⏱ ${formatearTiempoContraReloj(_segundosRestantesInicio)}',
                    style: TextStyle(
                      color: _segundosRestantesInicio <= 30
                          ? Colors.red.shade900
                          : Colors.deepOrange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          const AudioSettingsButton(),
        ],
      ),
      body: SafeArea(
        child: _tableroSeleccionado == null
            ? _buildSelectorTablero()
            : Column(
                children: [
                  const SizedBox(height: 8),
                  // BANNER SUPERIOR (Estructura alineada con JuegoScreen)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Configuración de inicio',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ubica los números del 1 al 6 en las casillas remarcadas para comenzar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Tablero $_tableroSeleccionado',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        tooltip: 'Ver reglas del tablero $_tableroSeleccionado',
                        onPressed: _mostrarReglasDelTablero,
                        icon: const Icon(Icons.menu_book_outlined),
                      ),
                      TextButton.icon(
                        onPressed: widget.multiplayer == null
                            ? () {
                                unawaited(
                                  AudioService.instance.reproducirBack(),
                                );
                                setState(() {
                                  _tableroSeleccionado = null;
                                  for (final fila in tablero.celdas) {
                                    fila.fillRange(0, fila.length, 0);
                                  }
                                  _posicionExplosion = null;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Cambiar tablero'),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _miConfiguracionCompletada
                          ? 'Tu tablero está listo. Esperando a los demás jugadores.'
                          : listo
                          ? '¡Todos los números colocados! Ya puedes iniciar.'
                          : 'Toca las casillas marcadas con borde grueso (+)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: listo
                            ? Colors.green.shade600
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.multiplayer != null) ...[
                    _buildMultiplayerSetupStatus(),
                    const SizedBox(height: 8),
                  ],
                  // TABLERO CENTRADO (EXPANDED CON ASPECT RATIO 1.0 IGUAL A JUEGO_SCREEN)
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
                            int valor = tablero.celdas[fila][columna];
                            Region region = _obtenerRegionCasilla(
                              fila,
                              columna,
                            );
                            bool esInicial = bloc.esPosicionInicial(
                              fila,
                              columna,
                            );
                            bool hayExplosionAqui =
                                _posicionExplosion != null &&
                                _posicionExplosion![0] == fila &&
                                _posicionExplosion![1] == columna;

                            return GestureDetector(
                              onTap: () => _alTocarCasilla(fila, columna),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    decoration: BoxDecoration(
                                      color: _colorParaRegion(region),
                                      border: Border.all(
                                        color: esInicial
                                            ? Colors.black87
                                            : Colors.black12,
                                        width: esInicial ? 3.0 : 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: esInicial
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.12,
                                                ),
                                                blurRadius: 3,
                                                offset: const Offset(1, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        valor == 0
                                            ? (esInicial ? '+' : '')
                                            : '$valor',
                                        style: TextStyle(
                                          fontSize: valor == 0 ? 20 : 22,
                                          fontWeight: FontWeight.bold,
                                          color: valor == 0
                                              ? Colors.black38
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (hayExplosionAqui)
                                    Positioned.fill(
                                      child: _EfectoExplosion(
                                        onFinished: () {
                                          setState(() {
                                            _posicionExplosion = null;
                                          });
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // BOTÓN INFERIOR (UBICADO DENTRO DEL COLUMN AL IGUAL QUE JUEGO_SCREEN)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            listo &&
                                !_miConfiguracionCompletada &&
                                !_enviandoConfiguracion &&
                                (widget.multiplayer?.canPlay ?? true)
                            ? () {
                                unawaited(
                                  AudioService.instance.reproducirSelect(),
                                );
                                final service = widget.multiplayer;
                                if (service == null) {
                                  _abrirJuego();
                                } else {
                                  _confirmarConfiguracionInicial();
                                }
                              }
                            : null,
                        icon: Icon(
                          _miConfiguracionCompletada || _enviandoConfiguracion
                              ? Icons.hourglass_top
                              : listo
                              ? Icons.check_circle_outline
                              : Icons.lock_outline,
                          size: 24,
                        ),
                        label: Text(
                          widget.multiplayer != null &&
                                  !widget.multiplayer!.canPlay
                              ? 'ESPERANDO CONEXIÓN'
                              : _miConfiguracionCompletada
                              ? 'ESPERANDO A LOS DEMÁS'
                              : _enviandoConfiguracion
                              ? 'ENVIANDO TABLERO...'
                              : listo
                              ? widget.multiplayer == null
                                    ? '¡LISTO! AVANZAR'
                                    : 'LISTO, ESPERAR JUGADORES'
                              : 'COLOCA LOS 6 NÚMEROS',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          elevation: listo ? 4 : 0,
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
    );
  }

  Widget _buildSelectorTablero() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Icon(Icons.dashboard_outlined, size: 40, color: Colors.blue),
              SizedBox(height: 8),
              Text(
                'Elige un tablero',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'Revisa cómo se ve cada tablero. Desliza hacia abajo para ver las cuatro opciones.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final numero = index + 1;
              return SizedBox(
                height: 144,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('seleccionar-tablero-$numero'),
                    onTap: () => _seleccionarTablero(numero),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          TableroPreview(
                            key: ValueKey('vista-previa-tablero-$numero'),
                            boardId: numero,
                            size: 112,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tablero $numero',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.touch_app_outlined,
                                        size: 18,
                                        color: Colors.blue.shade800,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Elegir',
                                        style: TextStyle(
                                          color: Colors.blue.shade900,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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

class _EfectoExplosion extends StatelessWidget {
  final VoidCallback onFinished;

  const _EfectoExplosion({required this.onFinished});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.8),
      duration: const Duration(milliseconds: 600),
      onEnd: onFinished,
      builder: (context, scale, child) {
        double opacity = (1.8 - scale) / 1.5;
        if (opacity < 0.0) opacity = 0.0;
        if (opacity > 1.0) opacity = 1.0;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.yellow.shade400,
                    Colors.deepOrange,
                    Colors.red.shade700.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: const Center(
                child: Text('💥', style: TextStyle(fontSize: 26)),
              ),
            ),
          ),
        );
      },
    );
  }
}
