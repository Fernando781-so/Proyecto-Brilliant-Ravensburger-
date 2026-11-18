import 'package:flutter/material.dart';

import 'brilliantravensburger.dart';

class ReglasTableroGuide extends StatelessWidget {
  const ReglasTableroGuide({super.key, required this.boardId});

  final int boardId;

  @override
  Widget build(BuildContext context) {
    if (boardId < 1 || boardId > 4) {
      return const Text('No hay instrucciones disponibles para este tablero.');
    }

    final reglas = _reglasPorTablero(boardId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Text(
                'Reglas por color y zona',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            for (var index = 0; index < reglas.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              _ReglaTableroTile(regla: reglas[index], index: index),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReglaTableroTile extends StatelessWidget {
  const _ReglaTableroTile({required this.regla, required this.index});

  final _ReglaTablero regla;
  final int index;

  @override
  Widget build(BuildContext context) {
    final zonas = regla.zonas.length == 1
        ? 'Zona ${regla.zonas.single}'
        : 'Zonas ${regla.zonas.join(', ')}';
    return ListTile(
      key: ValueKey('board-rule-${index + 1}'),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _colorRegion(regla.region),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black38),
        ),
        alignment: Alignment.center,
        child: Text(
          _simbolo(regla),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      title: Text(
        '${_nombreRegion(regla.region, regla)} · $zonas',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(_descripcion(regla)),
    );
  }
}

class _ReglaTablero {
  _ReglaTablero({
    required this.region,
    required this.valorMinimo,
    required this.valorMaximo,
  });

  final Region region;
  final int? valorMinimo;
  final int? valorMaximo;
  final List<int> zonas = [];
}

List<_ReglaTablero> _reglasPorTablero(int boardId) {
  final tablero = crearTablero(boardId);
  final reglas = <String, _ReglaTablero>{};

  for (var index = 0; index < tablero.zonas.length; index++) {
    final zona = tablero.zonas[index];
    final key = zona.region == Region.naranja
        ? '${zona.region.index}-${zona.valorMinimo}-${zona.valorMaximo}'
        : '${zona.region.index}';
    final regla = reglas.putIfAbsent(
      key,
      () => _ReglaTablero(
        region: zona.region,
        valorMinimo: zona.valorMinimo,
        valorMaximo: zona.valorMaximo,
      ),
    );
    regla.zonas.add(index + 1);
  }

  return reglas.values.toList();
}

String _nombreRegion(Region region, _ReglaTablero regla) {
  switch (region) {
    case Region.amarillo:
      return 'Amarillo';
    case Region.verde:
      return 'Verde';
    case Region.azul:
      return 'Azul';
    case Region.lila:
      return 'Morado';
    case Region.rojo:
      return 'Rojo';
    case Region.blanco:
      return 'Blanco';
    case Region.naranja:
      return 'Naranja ${regla.valorMinimo}-${regla.valorMaximo}';
  }
}

String _simbolo(_ReglaTablero regla) {
  switch (regla.region) {
    case Region.amarillo:
    case Region.rojo:
      return '≠';
    case Region.verde:
      return '?';
    case Region.azul:
    case Region.blanco:
      return '=';
    case Region.lila:
      return 'XO';
    case Region.naranja:
      return '${regla.valorMinimo}-${regla.valorMaximo}';
  }
}

String _descripcion(_ReglaTablero regla) {
  switch (regla.region) {
    case Region.amarillo:
    case Region.rojo:
      return 'Todos los números de la zona deben ser diferentes entre sí.';
    case Region.verde:
      return 'La zona acepta cualquier número.';
    case Region.azul:
    case Region.blanco:
      return 'Todos los números de la zona deben ser iguales.';
    case Region.lila:
      return 'La zona debe contener exactamente dos números distintos.';
    case Region.naranja:
      return 'La zona acepta números del ${regla.valorMinimo} al ${regla.valorMaximo}.';
  }
}

Color _colorRegion(Region region) {
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
