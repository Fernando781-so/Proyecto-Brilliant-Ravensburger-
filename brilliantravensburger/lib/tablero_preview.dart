import 'package:flutter/material.dart';

import 'brilliantravensburger.dart';

class TableroPreview extends StatelessWidget {
  const TableroPreview({super.key, required this.boardId, this.size = 64});

  final int boardId;
  final double size;

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
          final region = board.zonas
              .firstWhere(
                (zone) => zone.posiciones.any(
                  (position) => position[0] == row && position[1] == column,
                ),
              )
              .region;
          final isStartingPosition = startingPositions.any(
            (position) => position[0] == row && position[1] == column,
          );

          return DecoratedBox(
            decoration: BoxDecoration(
              color: _colorForRegion(region),
              border: Border.all(
                color: isStartingPosition ? Colors.black87 : Colors.black26,
                width: isStartingPosition ? 1.5 : 0.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        },
      ),
    );
  }
}
