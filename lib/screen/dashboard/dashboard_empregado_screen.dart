import 'package:flutter/material.dart';
import 'package:propertask/core/utils/formatters.dart';
import 'package:propertask/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/models/tarefa.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/services/firestore_service.dart';
import 'package:propertask/widgets/tarefa_card.dart';

class DashboardEmpregadoScreen extends StatelessWidget {
  const DashboardEmpregadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.user;
    final usuario = appState.usuario;

    final cs = Theme.of(context).colorScheme;

    if (user == null || usuario == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando usuário...'),
            ],
          ),
        ),
      );
    }

    final cargo = usuario.cargo?.toUpperCase() ?? '';
    final hoje = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${Formatters.formatDate(hoje)}'),
        backgroundColor: cs.surface,
        foregroundColor: cs.primary,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: StreamBuilder<List<Tarefa>>(
          stream: FirestoreService().getTarefasDoDia(hoje, user.uid, cargo),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _emptyState(cs);
            }
            final tarefas = snapshot.data!;
            final pendentes = tarefas
                .where((t) => t.status != 'concluida')
                .toList();
            final concluidas = tarefas
                .where((t) => t.status == 'concluida')
                .toList();

            // Calcula percentuais
            final percentConcluidas = tarefas.isNotEmpty
                ? (concluidas.length / tarefas.length * 100).round()
                : 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com avatar e saudação
                _headerUser(context, usuario, user, cs, percentConcluidas),
                const SizedBox(height: 18),
                // Cards stats
                Row(
                  children: [
                    _statCard(
                      context,
                      'Pendentes',
                      pendentes.length,
                      cs.primary,
                    ),
                    _statCard(
                      context,
                      'Concluídas',
                      concluidas.length,
                      cs.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildSection('Pendentes', pendentes, cs.primary),
                      _buildSection('Concluídas', concluidas, cs.secondary),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionar tarefa em breve!')),
          );
        },
      ),
    );
  }

  Widget _headerUser(
    BuildContext context,
    usuario,
    user,
    ColorScheme cs,
    int percentConcluidas,
  ) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: cs.primaryContainer,
          radius: 28,
          child: Icon(Icons.person, size: 28, color: cs.primary),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá,', style: TextStyle(fontSize: 16, color: cs.primary)),
            Text(
              usuario.nome ?? user.email ?? 'Usuário',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            Text(
              usuario.cargo ?? '',
              style: TextStyle(fontSize: 13, color: cs.outline),
            ),
            const SizedBox(height: 5),
            // Percentual de tarefas concluídas
            if (percentConcluidas > 0)
              Row(
                children: [
                  Icon(Icons.check_circle, color: cs.secondary, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$percentConcluidas% do dia concluído',
                    style: TextStyle(fontSize: 13, color: cs.secondary),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 58,
            color: cs.secondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 15),
          Text(
            'Nenhuma tarefa para hoje',
            style: TextStyle(fontSize: 18, color: cs.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, int value, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
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

  Widget _buildSection(String title, List<Tarefa> tarefas, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        collapsedBackgroundColor: color.withValues(alpha: 0.09),
        backgroundColor: color.withValues(alpha: 0.08),
        title: Text(
          '$title (${tarefas.length})',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: tarefas.map((t) => TarefaCard(tarefa: t)).toList(),
      ),
    );
  }
}
