import 'dart:async';

import 'package:flutter/material.dart';

import 'audio_service.dart';
import 'brilliantravensburger.dart';
import 'tablero_preview.dart';

String simboloReglaZona(Zona zone) {
  switch (zone.region) {
    case Region.azul:
    case Region.blanco:
      return '=';
    case Region.rojo:
    case Region.amarillo:
      return '≠';
    case Region.verde:
      return '?';
    case Region.lila:
      return 'XO';
    case Region.naranja:
      if (zone.valorMinimo != null && zone.valorMaximo != null) {
        return '${zone.valorMinimo}-${zone.valorMaximo}';
      }
      return 'N';
  }
}

String reglaColorZona(Zona zone) {
  switch (zone.region) {
    case Region.azul:
    case Region.blanco:
      return 'Todos los números de esa zona deben ser iguales.';
    case Region.rojo:
    case Region.amarillo:
      return 'Todos los números de esa zona deben ser diferentes.';
    case Region.verde:
      return 'Cualquier número (sin restricción).';
    case Region.lila:
      return 'Máximo 2 números diferentes en toda la zona.';
    case Region.naranja:
      if (zone.valorMinimo == 1 && zone.valorMaximo == 3) {
        return 'Solo números del 1 al 3.';
      }
      if (zone.valorMinimo == 4 && zone.valorMaximo == 6) {
        return 'Solo números del 4 al 6.';
      }
      if (zone.valorMinimo != null && zone.valorMaximo != null) {
        return 'Solo números del ${zone.valorMinimo} al ${zone.valorMaximo}.';
      }
      return 'Solo números dentro del rango permitido.';
  }
}

class ReglasTableroGuide extends StatefulWidget {
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
  State<ReglasTableroGuide> createState() => _ReglasTableroGuideState();
}

class _ReglasTableroGuideState extends State<ReglasTableroGuide> {
  int? _localSelectedZone;

  int? get _activeSelectedZone =>
      widget.onZoneSelected != null ? widget.selectedZone : _localSelectedZone;

  void _handleZoneTap(int index) {
    unawaited(AudioService.instance.reproducirSelect());
    if (widget.onZoneSelected != null) {
      widget.onZoneSelected!(index);
    } else {
      setState(() {
        _localSelectedZone = _localSelectedZone == index ? null : index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.boardId < 1 || widget.boardId > 4) {
      return const Text('No hay instrucciones disponibles para este tablero.');
    }

    final board = crearTablero(widget.boardId);
    final activeIndex = _activeSelectedZone;
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
                selected: activeIndex == index,
                onSelected: () => _handleZoneTap(index),
              ),
              if (activeIndex == index)
                _ZoneRulePreview(
                  boardId: widget.boardId,
                  zoneIndex: index,
                  zone: board.zonas[index],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ZoneRulePreview extends StatelessWidget {
  const _ZoneRulePreview({
    required this.boardId,
    required this.zoneIndex,
    required this.zone,
  });

  final int boardId;
  final int zoneIndex;
  final Zona zone;

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: ValueKey('zone-rule-preview-${zoneIndex + 1}'),
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: esOscuro ? Colors.grey.shade900 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esOscuro ? Colors.deepPurple.shade300 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TableroPreview(
            key: ValueKey('zone-board-preview-${zoneIndex + 1}'),
            boardId: boardId,
            size: 96,
            highlightedZoneIndex: zoneIndex,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Regla (${_nombreZona(zone)})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reglaColorZona(zone),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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
    final symbol = simboloReglaZona(zone);
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      key: ValueKey('board-zone-${index + 1}'),
      dense: true,
      selected: selected,
      selectedTileColor: esOscuro
          ? Colors.deepPurple.withValues(alpha: 0.25)
          : Colors.blue.shade50,
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
              symbol,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: symbol.length > 2 ? 12 : 15,
                color: Colors.black87,
              ),
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
