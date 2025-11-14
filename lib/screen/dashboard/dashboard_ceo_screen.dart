import 'package:flutter/material.dart';
import 'package:propertask/widgets/app_drawer.dart';

class DashboardCeoScreen extends StatelessWidget {
  const DashboardCeoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard CEO'),
        backgroundColor: cs.surface,
        foregroundColor: cs.primary,
        elevation: 0,
      ),
      drawer: AppDrawer(currentRoute: '/dashboard'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KPIs Rápidos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _statCard(context, 'Tarefas Totais', 198, cs.primary),
                _statCard(context, 'Taxa Conclusão', 92, cs.secondary),
                _statCard(context, 'Em atraso', 3, cs.error),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: Icon(Icons.bar_chart, color: cs.primary),
                title: const Text('Produtividade alta esta semana'),
                subtitle: const Text('95% das tarefas concluídas a tempo'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Icon(Icons.group, color: cs.primaryContainer),
                title: const Text('Equipes ativas: 7'),
                subtitle: const Text('2 equipes com alerta de atraso'),
              ),
            ),
            const SizedBox(height: 10),
            // Placeholder gráfico
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.show_chart, color: cs.primary, size: 38),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      'Gráfico de desempenho semanal (em breve)',
                      style: TextStyle(color: cs.outline),
                    ),
                  ),
                ],
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
