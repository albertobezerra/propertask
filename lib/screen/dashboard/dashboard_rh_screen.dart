import 'package:flutter/material.dart';
import 'package:propertask/widgets/app_drawer.dart';

class DashboardRhScreen extends StatelessWidget {
  const DashboardRhScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Mock: Dados do RH
    final equipeAtiva = 18;
    final admissaoHoje = 1;
    final pendentes = 3;

    final ferias = [
      {'nome': 'Ana', 'periodo': '14-20/11'},
      {'nome': 'Otávio', 'periodo': '15-25/11'},
    ];

    final aniversariantes = [
      {'nome': 'Carla', 'quando': 'Hoje'},
      {'nome': 'Luiz', 'quando': '16/11'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard RH'),
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
              'Equipe',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard(context, 'Ativos', equipeAtiva, cs.primary),
                _statCard(context, 'Admissão hoje', admissaoHoje, cs.secondary),
                _statCard(context, 'Pendentes RH', pendentes, cs.error),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Férias Agendadas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ...ferias.map(
              (f) => Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: Icon(Icons.beach_access, color: cs.secondary),
                  title: Text(f['nome'] as String),
                  subtitle: Text('Período: ${f['periodo']}'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Aniversariantes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ...aniversariantes.map(
              (a) => Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: Icon(Icons.cake, color: cs.primary),
                  title: Text(a['nome'] as String),
                  subtitle: Text(a['quando'] as String),
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
