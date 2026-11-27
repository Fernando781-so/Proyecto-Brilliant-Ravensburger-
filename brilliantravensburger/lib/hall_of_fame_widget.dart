import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_config.dart';
import 'audio_service.dart';
import 'multiplayer_service.dart';

class HallOfFameEntry {
  const HallOfFameEntry({
    required this.position,
    required this.id,
    required this.username,
    required this.rankedPoints,
    required this.rankedLevel,
    this.wins = 0,
    this.gamesPlayed = 0,
  });

  final int position;
  final String id;
  final String username;
  final int rankedPoints;
  final String rankedLevel;
  final int wins;
  final int gamesPlayed;

  factory HallOfFameEntry.fromJson(Map<String, dynamic> json, int fallbackPos) {
    final pts = (json['rankedPoints'] as num?)?.toInt() ?? eloInicial;
    final safePts = pts < eloMinimo ? eloInicial : pts;
    return HallOfFameEntry(
      position: (json['position'] as num?)?.toInt() ?? fallbackPos,
      id: '${json['id'] ?? ''}',
      username: '${json['username'] ?? 'Jugador'}',
      rankedPoints: safePts,
      rankedLevel:
          (json['rankedLevel'] as String?) ?? obtenerNivelRanked(safePts),
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
    );
  }
}

class HallOfFameData {
  const HallOfFameData({
    required this.top10,
    required this.currentUser,
  });

  final List<HallOfFameEntry> top10;
  final HallOfFameEntry currentUser;

  factory HallOfFameData.fromJson(Map<String, dynamic> json) {
    final rawList = (json['top10'] as List<dynamic>? ?? const []);
    final top10 = <HallOfFameEntry>[];
    for (var i = 0; i < rawList.length && i < 10; i++) {
      final item = rawList[i];
      if (item is Map) {
        top10.add(
          HallOfFameEntry.fromJson(Map<String, dynamic>.from(item), i + 1),
        );
      }
    }
    final rawMe = json['currentUser'];
    final currentUser = rawMe is Map
        ? HallOfFameEntry.fromJson(
            Map<String, dynamic>.from(rawMe),
            top10.length + 1,
          )
        : const HallOfFameEntry(
            position: 1,
            id: '',
            username: 'Jugador',
            rankedPoints: eloInicial,
            rankedLevel: 'Nuevo héroe',
          );
    return HallOfFameData(top10: top10, currentUser: currentUser);
  }
}

typedef HallOfFameLoader = Future<HallOfFameData> Function(String token);

class HallOfFameService {
  HallOfFameService._();

  static HallOfFameLoader? testLoader;

  static Future<HallOfFameData> fetch(String token) async {
    if (testLoader != null) {
      return testLoader!(token);
    }
    final response = await http
        .get(
          Uri.parse('$baseUrl/hall-of-fame'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el Salón de la Fama.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del Salón de la Fama.');
    }
    return HallOfFameData.fromJson(decoded);
  }
}

/// Tabla reutilizable del Salón de la Fama (Top 10 + posición fija del jugador actual abajo).
class HallOfFameTable extends StatelessWidget {
  const HallOfFameTable({
    super.key,
    required this.data,
    this.onMinimize,
    this.onRefresh,
    this.maxListHeight = 260,
  });

  final HallOfFameData data;
  final VoidCallback? onMinimize;
  final VoidCallback? onRefresh;
  final double maxListHeight;

  Color _badgeColor(int position, bool esOscuro) {
    if (position == 1) return Colors.amber.shade600;
    if (position == 2) return Colors.blueGrey.shade400;
    if (position == 3) return Colors.deepOrange.shade400;
    return esOscuro ? Colors.blue.shade700 : Colors.blue.shade600;
  }

  String _medalPrefix(int position) {
    if (position == 1) return '🥇';
    if (position == 2) return '🥈';
    if (position == 3) return '🥉';
    return '#$position';
  }

  Widget _buildRow(
    BuildContext context,
    HallOfFameEntry entry, {
    required bool isCurrentUser,
    bool isPinnedFooter = false,
  }) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final rowBg = isPinnedFooter
        ? (esOscuro ? const Color(0xFF16324F) : Colors.blue.shade50)
        : isCurrentUser
        ? (esOscuro ? const Color(0xFF3A2C12) : Colors.amber.shade50)
        : (entry.position <= 3
              ? (esOscuro
                    ? Colors.amber.withValues(alpha: 0.10)
                    : Colors.amber.shade50.withValues(alpha: 0.55))
              : Colors.transparent);

    return Container(
      key: isPinnedFooter
          ? const ValueKey('hall-of-fame-current-user')
          : ValueKey('hall-of-fame-row-${entry.position}'),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(10),
        border: isPinnedFooter
            ? Border.all(
                color: esOscuro
                    ? Colors.lightBlue.shade300
                    : Colors.blue.shade600,
                width: 1.5,
              )
            : isCurrentUser
            ? Border.all(
                color: esOscuro ? Colors.amber.shade300 : Colors.amber.shade700,
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _badgeColor(entry.position, esOscuro),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _medalPrefix(entry.position),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPinnedFooter
                      ? '${entry.username} (Tú)'
                      : isCurrentUser
                      ? '${entry.username} (Tú)'
                      : entry.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isCurrentUser || isPinnedFooter
                        ? FontWeight.bold
                        : FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  entry.rankedLevel,
                  style: TextStyle(
                    fontSize: 11,
                    color: esOscuro ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.rankedPoints} pts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: esOscuro ? Colors.amber.shade200 : Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              size: 18,
              color: esOscuro ? Colors.amber.shade300 : Colors.amber.shade800,
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Salón de la Fama · Top 10',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            if (onRefresh != null)
              IconButton(
                tooltip: 'Actualizar tabla',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            if (onMinimize != null)
              TextButton.icon(
                key: const ValueKey('profile-ranked-hall-minimize'),
                onPressed: onMinimize,
                icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                label: const Text('Minimizar'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (data.top10.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Aún no hay jugadores registrados en el Salón de la Fama.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: data.top10.length,
              itemBuilder: (context, index) {
                final entry = data.top10[index];
                final isMe =
                    (data.currentUser.id.isNotEmpty &&
                        entry.id == data.currentUser.id) ||
                    entry.username == data.currentUser.username;
                return _buildRow(context, entry, isCurrentUser: isMe);
              },
            ),
          ),
        const Divider(height: 14),
        Text(
          'Tu posición actual',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: esOscuro ? Colors.lightBlue.shade200 : Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 4),
        _buildRow(
          context,
          data.currentUser,
          isCurrentUser: true,
          isPinnedFooter: true,
        ),
      ],
    );
  }
}

/// Abre un diálogo modal con el Salón de la Fama (usado desde Crear sala).
Future<void> mostrarSalonDeLaFamaDialog(
  BuildContext context, {
  required String token,
}) {
  unawaited(AudioService.instance.reproducirSelect());
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _HallOfFameDialog(token: token),
  );
}

class _HallOfFameDialog extends StatefulWidget {
  const _HallOfFameDialog({required this.token});

  final String token;

  @override
  State<_HallOfFameDialog> createState() => _HallOfFameDialogState();
}

class _HallOfFameDialogState extends State<_HallOfFameDialog> {
  late Future<HallOfFameData> _future;

  @override
  void initState() {
    super.initState();
    _future = HallOfFameService.fetch(widget.token);
  }

  void _reload() {
    setState(() {
      _future = HallOfFameService.fetch(widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('hall-of-fame-dialog'),
      title: const Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.amber),
          SizedBox(width: 8),
          Expanded(child: Text('Salón de la Fama')),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<HallOfFameData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No se pudo cargar el Salón de la Fama.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              );
            }
            return HallOfFameTable(
              data: snapshot.data!,
              onRefresh: _reload,
              maxListHeight: 300,
            );
          },
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            unawaited(AudioService.instance.reproducirBack());
            Navigator.of(context).pop();
          },
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
