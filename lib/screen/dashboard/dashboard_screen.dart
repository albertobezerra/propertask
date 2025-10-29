// lib/screen/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:propertask/core/utils/formatters.dart';
import 'package:propertask/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/models/tarefa.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/services/firestore_service.dart';
import 'package:propertask/widgets/tarefa_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppState>(context).user!;
    final cargo = Provider.of<AppState>(context).usuario?.cargo ?? 'LIMPEZA';
    final hoje = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${Formatters.formatDate(hoje)}'),
        backgroundColor: Colors.blue.shade700,
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'), // AQUI!
      body: StreamBuilder<List<Tarefa>>(
        stream: FirestoreService().getTarefasDoDia(hoje, user.uid, cargo),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tarefas = snapshot.data!;

          final pendentes = tarefas
              .where((t) => t.status != 'concluida')
              .toList();
          final concluidas = tarefas
              .where((t) => t.status == 'concluida')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _buildSection('Pendentes', pendentes, Colors.orange),
              _buildSection('Concluídas', concluidas, Colors.green),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add),
        onPressed: () {
          // Futuro Adicionar Tarefa
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionar tarefa em breve!')),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Tarefa> tarefas, Color color) {
    return Card(
      elevation: 3,
      child: ExpansionTile(
        title: Text(
          '$title (${tarefas.length})',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        children: tarefas.map((t) => TarefaCard(tarefa: t)).toList(),
      ),
    );
  }
}
