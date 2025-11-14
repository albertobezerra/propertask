import 'package:flutter/material.dart';
import 'package:propertask/widgets/app_drawer.dart';

class DashboardLavanderiaScreen extends StatelessWidget {
  const DashboardLavanderiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Mock dados de lavagens
    final lavagensPendentes = 5;
    final lavagensConcluidas = 18;
    final tempoMedio = 42; // minutos

    final relatorioDia = [
      {'propriedade': 'Hotel Azul', 'itens': 12, 'status': 'Concluído'},
      {'propriedade': 'Residencial X', 'itens': 4, 'status': 'Pendente'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Lavanderia'),
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
              'Resumo Diário',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard(context, 'Pendentes', lavagensPendentes, cs.primary),
                _statCard(
                  context,
                  'Concluídas',
                  lavagensConcluidas,
                  cs.secondary,
                ),
                _statCard(context, 'Média (min)', tempoMedio, cs.outline),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Relatório do Dia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ...relatorioDia.map(
              (r) => Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: Icon(
                    r['status'] == 'Concluído'
                        ? Icons.done
                        : Icons.pending_actions,
                    color: r['status'] == 'Concluído'
                        ? cs.secondary
                        : cs.primary,
                  ),
                  title: Text(r['propriedade'] as String),
                  subtitle: Text(
                    'Itens: ${r['itens']} • Status: ${r['status']}',
                  ),
                ),
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
