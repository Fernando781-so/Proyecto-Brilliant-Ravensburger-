import 'package:flutter/material.dart';

import 'brilliantravensburger.dart';

class ReglasTableroGuide extends StatelessWidget {
  const ReglasTableroGuide({
    super.key,
    required this.boardId,
    this.selectedZone,
    this.onZoneSelected,
  });

  final int boardId;
  final int? selectedZone;
  final ValueChanged<int>? onZoneSelected;

  @override
  Widget build(BuildContext context) {
    if (boardId < 1 || boardId > 4) {
      return const Text('No hay instrucciones disponibles para este tablero.');
    }

    final board = crearTablero(boardId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Text(
                'Puntos de las zonas',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            for (var index = 0; index < board.zonas.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              _ZonePointsTile(
                index: index,
                zone: board.zonas[index],
                selected: selectedZone == index,
                onSelected: onZoneSelected == null
                    ? null
                    : () => onZoneSelected!(index),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ZonePointsTile extends StatelessWidget {
  const _ZonePointsTile({
    required this.index,
    required this.zone,
    required this.selected,
    required this.onSelected,
  });

  final int index;
  final Zona zone;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final points = zone.bolsaPuntos.join(' → ');
    return ListTile(
      key: ValueKey('board-zone-${index + 1}'),
      dense: true,
      selected: selected,
      selectedTileColor: Colors.blue.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: onSelected,
      leading: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('zone-color-${index + 1}'),
          customBorder: const CircleBorder(),
          onTap: onSelected,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _colorRegion(zone.region),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.deepPurple : Colors.black38,
                width: selected ? 3 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      title: Text(
        'Zona ${index + 1} · ${_nombreZona(zone)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('Puntos: $points'),
    );
  }
}

String _nombreZona(Zona zone) {
  if (zone.region == Region.naranja &&
      zone.valorMinimo != null &&
      zone.valorMaximo != null) {
    return 'Naranja ${zone.valorMinimo}-${zone.valorMaximo}';
  }
  switch (zone.region) {
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
      return 'Naranja';
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
