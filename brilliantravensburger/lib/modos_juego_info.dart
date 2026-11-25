import 'dart:async';

import 'package:flutter/material.dart';

import 'audio_service.dart';

/// Muestra un diálogo con las reglas generales y la información de todos los modos de juego.
Future<void> mostrarReglasModosJuego(BuildContext context) {
  unawaited(AudioService.instance.reproducirSelect());
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final esOscuro = Theme.of(dialogContext).brightness == Brightness.dark;
      final cardBg = esOscuro
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.blueGrey.shade50;
      final borderColor = esOscuro ? Colors.white24 : Colors.blueGrey.shade100;

      Widget buildSection({
        required IconData icon,
        required Color iconColor,
        required String title,
        required String body,
      }) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(body, style: const TextStyle(fontSize: 12.5, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return AlertDialog(
        key: const ValueKey('game-modes-info-dialog'),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text('Reglas y modos de juego')),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSection(
                  icon: Icons.grid_on_rounded,
                  iconColor: Colors.blue,
                  title: 'Reglas básicas',
                  body:
                      '1. Coloca los números del 1 al 6 en las 6 casillas iniciales.\n'
                      '2. En cada turno salen 2 dados: elige uno como ancla y coloca el otro en una casilla vacía adyacente en cruz (+).\n'
                      '3. Completa zonas cumpliendo la regla de su color (= iguales, ≠ diferentes, ? cualquiera, XO máx. 2 distintos, 1-3 o 4-6) para sumar puntos.',
                ),
                buildSection(
                  icon: Icons.person_outline,
                  iconColor: Colors.green,
                  title: 'Jugar sin conexión',
                  body:
                      'Partida individual en cualquiera de los 4 tableros. Ideal para practicar estrategias sin límite de tiempo ni cambios en tu clasificación.',
                ),
                buildSection(
                  icon: Icons.sports_esports_outlined,
                  iconColor: Colors.teal,
                  title: 'Modo Casual (2 a 6 jugadores)',
                  body:
                      'Partida multijugador en línea amistosa. Todos juegan con el mismo tablero y los mismos dados por turno, sin modificar tus puntos de clasificatoria.',
                ),
                buildSection(
                  icon: Icons.emoji_events,
                  iconColor: Colors.amber.shade700,
                  title: 'Modo Clasificatoria (Ranked)',
                  body:
                      'Modo competitivo de 2 a 6 jugadores con 5 rangos:\n'
                      '• Principiante (100–999 pts)\n'
                      '• Nuevo héroe (1000–1149 pts)\n'
                      '• Experto (1150–1299 pts)\n'
                      '• Megamente (1300–1499 pts)\n'
                      '• EL Brilliant (1500+ pts)\n'
                      'Al finalizar, tus puntos suben o bajan según tu posición y el nivel de tus rivales (piso mínimo: 100 pts).',
                ),
                buildSection(
                  icon: Icons.timer,
                  iconColor: Colors.deepOrange,
                  title: 'Modo Contra reloj',
                  body:
                      'Se puede combinar con Casual o Clasificatoria.\n'
                      '• 5 minutos para colocar tus 6 números iniciales.\n'
                      '• 2 minutos por turno.\n'
                      'Si colocaste un número sin confirmar antes de llegar a 00:00, se acepta automáticamente; si no colocaste nada, se salta el turno.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              unawaited(AudioService.instance.reproducirBack());
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Entendido'),
          ),
        ],
      );
    },
  );
}
