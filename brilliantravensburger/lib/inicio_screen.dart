import 'package:flutter/material.dart';
import 'brilliantravensburger.dart';
import 'juego_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late Tablero tablero;
  late InicioBloc bloc;

  List<int>? _posicionExplosion;

  @override
  void initState() {
    super.initState();
    tablero = Tablero(
      celdas: List.generate(7, (_) => List.generate(7, (_) => 0)),
      zonas: zonas,
    );
    bloc = InicioBloc(tablero: tablero);
  }

  Region _obtenerRegionCasilla(int fila, int columna) {
    for (var zona in tablero.zonas) {
      if (zona.posiciones.any((p) => p[0] == fila && p[1] == columna)) {
        return zona.region;
      }
    }
    return Region.verde;
  }

  void _alTocarCasilla(int fila, int columna) {
    if (!bloc.esPosicionInicial(fila, columna)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toca una casilla con borde grueso para colocar un número.'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _mostrarMenuSeleccionNumero(fila, columna);
  }

  void _mostrarMenuSeleccionNumero(int fila, int columna) {
    int valorActual = tablero.celdas[fila][columna];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  bool estaUsadoEnOtraParte = bloc.numeroYaUtilizado(num) && !esElMismo;

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
                          if (tablero.celdas[r][c] == num && !(r == fila && c == columna)) {
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

                        Navigator.of(context).pop();

                        if (origenAnterior != null) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '💥 ¡El número $num cambió de casilla!',
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
                    setState(() {
                      _posicionExplosion = [fila, columna];
                      tablero.celdas[fila][columna] = 0;
                    });
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Quitar número',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
        title: const Text('Brilliant - Posiciones Iniciales'),
        centerTitle: true,
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
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
                      Icon(Icons.touch_app_outlined, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Configuración de inicio',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                listo
                    ? '¡Todos los números colocados! Ya puedes iniciar.'
                    : 'Toca las casillas marcadas con borde grueso (+)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: listo ? Colors.green.shade800 : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // TABLERO CENTRADO (EXPANDED CON ASPECT RATIO 1.0 IGUAL A JUEGO_SCREEN)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: 49,
                    itemBuilder: (context, index) {
                      int fila = index ~/ 7;
                      int columna = index % 7;
                      int valor = tablero.celdas[fila][columna];
                      Region region = _obtenerRegionCasilla(fila, columna);
                      bool esInicial = bloc.esPosicionInicial(fila, columna);
                      bool hayExplosionAqui = _posicionExplosion != null &&
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
                                  color: esInicial ? Colors.black87 : Colors.black12,
                                  width: esInicial ? 3.0 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: esInicial
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 3,
                                          offset: const Offset(1, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  valor == 0 ? (esInicial ? '+' : '') : '$valor',
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
                  onPressed: listo
                      ? () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => JuegoScreen(tablero: tablero),
                            ),
                          );
                        }
                      : null,
                  icon: Icon(
                    listo ? Icons.check_circle_outline : Icons.lock_outline,
                    size: 24,
                  ),
                  label: Text(
                    listo ? '¡LISTO! AVANZAR' : 'COLOCA LOS 6 NÚMEROS',
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
                    Colors.red.shade700.withOpacity(0.0),
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  '💥',
                  style: TextStyle(fontSize: 26),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}