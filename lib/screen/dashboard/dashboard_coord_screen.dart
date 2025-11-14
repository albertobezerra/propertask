import 'package:flutter/material.dart';

class DashboardCoordScreen extends StatelessWidget {
  const DashboardCoordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Mock dados de equipe
    final equipeResumo = [
      {'nome': 'Julia', 'pendentes': 2, 'concluidas': 6},
      {'nome': 'Carlos', 'pendentes': 1, 'concluidas': 8},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Coordenador'),
        backgroundColor: cs.surface,
        foregroundColor: cs.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do Dia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _statCard(context, 'Pendentes', 6, cs.primary),
                _statCard(context, 'Concluídas', 22, cs.secondary),
                _statCard(context, 'Atrasadas', 1, cs.error),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Equipe',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ...equipeResumo.map(
              (m) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text(m['nome'] as String),
                  subtitle: Text(
                    'Pendentes: ${m['pendentes']}  •  Concluídas: ${m['concluidas']}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Timeline do Dia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.calendar_today, color: cs.primary),
                title: const Text('Limpeza Propriedade A - 9:30'),
                subtitle: const Text('Por Julia • Pendentes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 15, color: color)),
          ],
        ),
      ),
    );
  }
}
