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
    final appState = Provider.of<AppState>(context);
    final user = appState.user;
    final usuario = appState.usuario;

    // SE AINDA NÃO CARREGOU → LOADING
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
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: StreamBuilder<List<Tarefa>>(
        stream: FirestoreService().getTarefasDoDia(hoje, user.uid, cargo),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Nenhuma tarefa para hoje',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final tarefas = snapshot.data!;
          final pendentes = tarefas
              .where((t) => t.status != 'concluida')
              .toList();
          final concluidas = tarefas
              .where((t) => t.status == 'concluida')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildSection('Pendentes', pendentes, Colors.orange),
              _buildSection('Concluídas', concluidas, Colors.green),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionar tarefa em breve!')),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Tarefa> tarefas, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        collapsedBackgroundColor: color.withValues(alpha: 0.1),
        backgroundColor: color.withValues(alpha: 0.1),
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
