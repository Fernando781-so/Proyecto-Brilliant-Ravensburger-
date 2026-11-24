import 'package:flutter/material.dart';

import 'brilliantravensburger.dart';

class TableroPreview extends StatelessWidget {
  const TableroPreview({
    super.key,
    required this.boardId,
    this.size = 64,
    this.highlightedZoneIndex,
  });

  final int boardId;
  final double size;
  final int? highlightedZoneIndex;

  Color _colorForRegion(Region region) {
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

  @override
  Widget build(BuildContext context) {
    final board = crearTablero(boardId);
    final startingPositions = obtenerPosicionesInicialesTablero(boardId);

    return SizedBox(
      width: size,
      height: size,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 1.5,
          mainAxisSpacing: 1.5,
        ),
        itemCount: 49,
        itemBuilder: (context, index) {
          final row = index ~/ 7;
          final column = index % 7;
          final zoneIndex = board.zonas.indexWhere(
            (zone) => zone.posiciones.any(
              (position) => position[0] == row && position[1] == column,
            ),
          );
          final region = zoneIndex >= 0
              ? board.zonas[zoneIndex].region
              : Region.verde;
          final isStartingPosition = startingPositions.any(
            (position) => position[0] == row && position[1] == column,
          );
          final hasHighlight = highlightedZoneIndex != null;
          final isHighlighted = hasHighlight && zoneIndex == highlightedZoneIndex;
          final baseColor = _colorForRegion(region);

          return DecoratedBox(
            decoration: BoxDecoration(
              color: hasHighlight && !isHighlighted
                  ? baseColor.withValues(alpha: 0.3)
                  : baseColor,
              border: Border.all(
                color: isHighlighted
                    ? Colors.deepPurple
                    : isStartingPosition
                    ? Colors.black87
                    : Colors.black26,
                width: isHighlighted
                    ? 2.2
                    : isStartingPosition
                    ? 1.5
                    : 0.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        },
      ),
    );
  }
}
