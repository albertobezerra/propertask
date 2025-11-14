import 'package:flutter/material.dart';
import 'package:propertask/widgets/app_drawer.dart';

class DashboardDevScreen extends StatelessWidget {
  const DashboardDevScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard DEV'),
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
              'Monitoramento Técnico',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _statCard(context, 'Req API', 1372, cs.primary),
                _statCard(context, 'Falhas', 2, cs.error),
                _statCard(context, 'Alertas', 1, cs.secondary),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: Icon(Icons.warning, color: cs.error),
                title: const Text('2 Exceptions recentes'),
                subtitle: const Text('Ver logs detalhados no Firebase'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Icon(Icons.update, color: cs.primary),
                title: const Text('Último Deploy: 14/11/2025'),
                subtitle: const Text('Deploy bem-sucedido'),
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
