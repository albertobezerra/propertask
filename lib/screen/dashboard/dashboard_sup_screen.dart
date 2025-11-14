import 'package:flutter/material.dart';

class DashboardSupScreen extends StatelessWidget {
  const DashboardSupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Mock tarefas tipo
    final tarefasPorTipo = [
      {'tipo': 'Limpeza', 'pendentes': 3, 'concluidas': 10},
      {'tipo': 'Lavanderia', 'pendentes': 1, 'concluidas': 5},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Supervisor'),
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
              'Resumo Rápido',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _statCard(context, 'Pendentes', 4, cs.primary),
                _statCard(context, 'Concluídas', 15, cs.secondary),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Por Tipo de Tarefa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ...tarefasPorTipo.map(
              (m) => Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: Icon(Icons.task_alt, color: cs.primary),
                  title: Text(m['tipo'] as String),
                  subtitle: Text(
                    'Pendentes: ${m['pendentes']}  •  Concluídas: ${m['concluidas']}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Alertas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.warning_amber, color: cs.error),
                title: const Text('2 tarefas em atraso!'),
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
