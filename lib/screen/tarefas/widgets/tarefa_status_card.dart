import 'package:flutter/material.dart';
import 'package:timer_builder/timer_builder.dart';

class TarefaStatusCard extends StatelessWidget {
  final String status;
  final String responsavelNome;
  final String dataFormatada;
  final DateTime? inicioEm;
  final DateTime? concluidaEm;

  const TarefaStatusCard({
    super.key,
    required this.status,
    required this.responsavelNome,
    required this.dataFormatada,
    required this.inicioEm,
    required this.concluidaEm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5), // Fundo suave
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // LINHA 1: Status e Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusChip(status: status),
                if (_duracaoTarefa != null) ...[
                  if (status == 'em_andamento' || status == 'reaberta')
                    TimerBuilder.periodic(
                      const Duration(seconds: 1),
                      builder: (_) => _buildTimerBadge(cs, isActive: true),
                    ),
                  if (status == 'concluida')
                    _buildTimerBadge(cs, isActive: false),
                ],
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.5), // Divisória fina
            const SizedBox(height: 12),

            // LINHA 2: Responsável e Data
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person, size: 16, color: cs.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Responsável",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        responsavelNome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Data",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      dataFormatada,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBadge(ColorScheme cs, {required bool isActive}) {
    final d = status == 'concluida'
        ? _duracaoTarefa!
        : DateTime.now().difference(inicioEm!);

    // Formatação com segundos (HH:MM:SS ou MM:SS)
    String text;
    final horas = d.inHours.toString().padLeft(2, '0');
    final minutos = (d.inMinutes % 60).toString().padLeft(2, '0');
    final segundos = (d.inSeconds % 60).toString().padLeft(2, '0');

    if (d.inHours > 0) {
      text = '$horas:$minutos:$segundos';
    } else {
      text = '$minutos:$segundos';
    }

    return Container(
      // ... resto do código de decoração (Container) igual ...
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Adicionei uma animaçãozinha no ícone se estiver ativo
          isActive
              ? _BlinkingIcon(icon: Icons.timer, color: Colors.blue[700]!)
              : Icon(Icons.timer_off, size: 14, color: Colors.grey[700]),

          const SizedBox(width: 4),

          // Fonte mono-espaçada evita que o texto "pule" quando os segundos mudam
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ], // IMPORTANTE: Números fixos
              color: isActive ? Colors.blue[700] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Duration? get _duracaoTarefa {
    if (inicioEm != null && concluidaEm != null) {
      return concluidaEm!.difference(inicioEm!);
    }
    if (inicioEm != null &&
        (status == 'em_andamento' || status == 'reaberta')) {
      return DateTime.now().difference(inicioEm!);
    }
    return null;
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'em_andamento':
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        label = 'Em Andamento';
        break;
      case 'concluida':
        bg = Colors.green.shade50;
        text = Colors.green.shade900;
        label = 'Concluída';
        break;
      case 'reaberta':
        bg = Colors.red.shade50;
        text = Colors.red.shade800;
        label = 'Reaberta';
        break;
      case 'pendente':
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade800;
        label = 'Aguardando Início';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: text.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _BlinkingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _BlinkingIcon({required this.icon, required this.color});

  @override
  State<_BlinkingIcon> createState() => _BlinkingIconState();
}

class _BlinkingIconState extends State<_BlinkingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Icon(widget.icon, size: 14, color: widget.color),
    );
  }
}
