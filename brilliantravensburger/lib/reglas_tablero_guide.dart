import 'package:flutter/material.dart';

class ReglasTableroGuide extends StatelessWidget {
  const ReglasTableroGuide({super.key, required this.boardId});

  final int boardId;

  @override
  Widget build(BuildContext context) {
    final reglas = _reglasPorTablero[boardId];
    if (reglas == null) {
      return const Text('No hay instrucciones disponibles para este tablero.');
    }

    return Column(
      children: [
        for (var index = 0; index < reglas.length; index++)
          _ReglaTableroTile(regla: reglas[index], index: index),
      ],
    );
  }
}

class _ReglaTableroTile extends StatelessWidget {
  const _ReglaTableroTile({required this.regla, required this.index});

  final _ReglaTablero regla;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('board-rule-${index + 1}'),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: regla.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black38),
        ),
        alignment: Alignment.center,
        child: Text(
          regla.simbolo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      title: Text(
        '${regla.nombre} (${regla.simbolo})',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(regla.descripcion),
    );
  }
}

class _ReglaTablero {
  const _ReglaTablero({
    required this.nombre,
    required this.simbolo,
    required this.descripcion,
    required this.color,
  });

  final String nombre;
  final String simbolo;
  final String descripcion;
  final Color color;
}

const Map<int, List<_ReglaTablero>> _reglasPorTablero = {
  1: [
    _ReglaTablero(
      nombre: 'Azul',
      simbolo: '=',
      descripcion: 'Conecta a la zona azul superior.',
      color: Color(0xFF90CAF9),
    ),
    _ReglaTablero(
      nombre: 'Verde',
      simbolo: '?',
      descripcion: 'Conecta a la franja verde superior.',
      color: Color(0xFFA5D6A7),
    ),
    _ReglaTablero(
      nombre: 'Rojo',
      simbolo: '≠',
      descripcion: 'Conecta a la zona roja izquierda.',
      color: Color(0xFFEF9A9A),
    ),
    _ReglaTablero(
      nombre: 'Morado',
      simbolo: 'XO',
      descripcion:
          'Conecta a las casillas moradas de la esquina inferior izquierda.',
      color: Color(0xFFCE93D8),
    ),
    _ReglaTablero(
      nombre: 'Morado',
      simbolo: 'XO',
      descripcion: 'Conecta a la zona morada central-derecha.',
      color: Color(0xFFCE93D8),
    ),
    _ReglaTablero(
      nombre: 'Amarillo',
      simbolo: '≠',
      descripcion:
          'No tiene línea: engloba las 5 casillas amarillas aisladas de las esquinas y el centro; tienen que ser 5 números distintos entre sí.',
      color: Color(0xFFFFE082),
    ),
    _ReglaTablero(
      nombre: 'Verde',
      simbolo: '?',
      descripcion: 'Conecta a la franja verde inferior.',
      color: Color(0xFFA5D6A7),
    ),
    _ReglaTablero(
      nombre: 'Azul',
      simbolo: '=',
      descripcion: 'Conecta a la zona azul inferior.',
      color: Color(0xFF90CAF9),
    ),
    _ReglaTablero(
      nombre: 'Rojo',
      simbolo: '≠',
      descripcion: 'Conecta a la zona roja inferior.',
      color: Color(0xFFEF9A9A),
    ),
  ],
  2: [
    _ReglaTablero(
      nombre: 'Amarillo',
      simbolo: '≠',
      descripcion: 'Conecta a la tira amarilla vertical izquierda.',
      color: Color(0xFFFFE082),
    ),
    _ReglaTablero(
      nombre: 'Morado',
      simbolo: 'XO',
      descripcion: 'Conecta a la zona morada superior izquierda.',
      color: Color(0xFFCE93D8),
    ),
    _ReglaTablero(
      nombre: 'Rojo',
      simbolo: '≠',
      descripcion: 'Conecta a la zona roja de la izquierda.',
      color: Color(0xFFEF9A9A),
    ),
    _ReglaTablero(
      nombre: 'Azul',
      simbolo: '=',
      descripcion: 'Conecta a la zona azul central.',
      color: Color(0xFF90CAF9),
    ),
    _ReglaTablero(
      nombre: 'Verde',
      simbolo: '?',
      descripcion: 'Conecta a la zona verde inferior izquierda.',
      color: Color(0xFFA5D6A7),
    ),
    _ReglaTablero(
      nombre: 'Verde',
      simbolo: '?',
      descripcion: 'Conecta a la zona verde superior derecha.',
      color: Color(0xFFA5D6A7),
    ),
    _ReglaTablero(
      nombre: 'Azul',
      simbolo: '=',
      descripcion: 'Conecta a la zona azul superior.',
      color: Color(0xFF90CAF9),
    ),
    _ReglaTablero(
      nombre: 'Rojo',
      simbolo: '≠',
      descripcion: 'Conecta a la zona roja derecha.',
      color: Color(0xFFEF9A9A),
    ),
    _ReglaTablero(
      nombre: 'Morado',
      simbolo: 'XO',
      descripcion: 'Conecta a la zona morada derecha.',
      color: Color(0xFFCE93D8),
    ),
    _ReglaTablero(
      nombre: 'Gris',
      simbolo: '=',
      descripcion:
          'No tiene línea: engloba las 3 casillas grises separadas (arriba, en medio y abajo); las tres deben tener exactamente el mismo número.',
      color: Color(0xFFB0BEC5),
    ),
  ],
  3: [
    _ReglaTablero(
      nombre: 'Morado',
      simbolo: 'XO',
      descripcion: 'Conecta al bloque morado grande de arriba.',
      color: Color(0xFFCE93D8),
    ),
    _ReglaTablero(
      nombre: 'Rojo',
      simbolo: '≠',
      descripcion: 'Conecta a la mitad izquierda de la franja roja central.',
      color: Color(0xFFEF9A9A),
    ),
    _ReglaTablero(
      nombre: 'Azul',
      simbolo: '=',
      descripcion: 'Conecta a toda la fila horizontal azul.',
      color: Color(0xFF90CAF9),
    ),
    _ReglaTablero(
      nombre: 'Morado',
      simbolo: 'XO',
      descripcion: 'Conecta al bloque morado inferior izquierdo.',
      color: Color(0xFFCE93D8),
    ),
    _ReglaTablero(
      nombre: 'Amarillo',
      simbolo: '≠',
      descripcion:
          'No tiene línea: engloba las dos columnas verticales amarillas (izquierda y derecha) como una sola zona de 6 casillas; todas deben ser diferentes, del 1 al 6.',
      color: Color(0xFFFFE082),
    ),
    _ReglaTablero(
      nombre: 'Rojo',
      simbolo: '≠',
      descripcion: 'Conecta a la mitad derecha de la franja roja central.',
      color: Color(0xFFEF9A9A),
    ),
    _ReglaTablero(
      nombre: 'Verde',
      simbolo: '?',
      descripcion:
          'No tiene línea: engloba todas las casillas verdes (la fila larga de abajo más la casilla verde solitaria de la fila inferior).',
      color: Color(0xFFA5D6A7),
    ),
    _ReglaTablero(
      nombre: 'Gris',
      simbolo: '=',
      descripcion:
          'No tiene línea: engloba las 5 casillas grises repartidas por el tablero; todas deben llevar el mismo número.',
      color: Color(0xFFB0BEC5),
    ),
  ],
  4: [
    _ReglaTablero(
      nombre: 'Morado',
      simbolo: 'XO',
      descripcion:
          'Conecta al bloque morado central de 7 casillas: incluye las tres superiores, la central y las tres inferiores.',
      color: Color(0xFFCE93D8),
    ),
    _ReglaTablero(
      nombre: 'Azul',
      simbolo: '=',
      descripcion:
          'Las 6 casillas azules de las dos columnas interiores forman una sola zona y deben llevar el mismo número; no hay una zona azul separada a la derecha.',
      color: Color(0xFF90CAF9),
    ),
    _ReglaTablero(
      nombre: 'Rojo',
      simbolo: '≠',
      descripcion:
          'Conecta las 6 casillas rojas de las columnas exterior e interior del lado izquierdo; todas deben ser diferentes.',
      color: Color(0xFFEF9A9A),
    ),
    _ReglaTablero(
      nombre: 'Naranja',
      simbolo: '1-3',
      descripcion:
          'Conecta a las 7 casillas de la fila horizontal naranja inferior (solo números 1, 2 o 3).',
      color: Color(0xFFFFCC80),
    ),
    _ReglaTablero(
      nombre: 'Naranja',
      simbolo: '4-6',
      descripcion:
          'Conecta a las 7 casillas de la fila horizontal naranja superior (solo números 4, 5 o 6).',
      color: Color(0xFFFFCC80),
    ),
    _ReglaTablero(
      nombre: 'Rojo',
      simbolo: '≠',
      descripcion:
          'Conecta las 6 casillas rojas de las columnas exterior e interior del lado derecho; todas deben ser diferentes.',
      color: Color(0xFFEF9A9A),
    ),
    _ReglaTablero(
      nombre: 'Amarillo',
      simbolo: '≠',
      descripcion:
          'Las 6 casillas amarillas de las dos columnas exteriores forman una sola zona; todas deben ser diferentes.',
      color: Color(0xFFFFE082),
    ),
    _ReglaTablero(
      nombre: 'Verde',
      simbolo: '?',
      descripcion:
          'Incluye las 4 casillas verdes del patrón central: una arriba, dos a los lados y una abajo. Se puede colocar cualquier número.',
      color: Color(0xFFA5D6A7),
    ),
  ],
};
