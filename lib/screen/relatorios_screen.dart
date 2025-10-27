import 'package:flutter/material.dart';
import 'package:propertask/core/models/propriedade.dart';
import 'package:propertask/core/models/tarefa.dart';
import 'package:propertask/core/services/firestore_service.dart';
import 'package:propertask/widgets/loading_widget.dart';

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas de Tarefas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<List<Tarefa>>(
              stream: _firestoreService.getTarefas(
                '',
              ), // Passa '' para obter todas
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }
                if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Nenhuma tarefa encontrada.');
                }

                final tarefas = snapshot.data!;
                final totalTarefas = tarefas.length;
                final tarefasConcluidas = tarefas
                    .where((t) => t.status == 'concluída')
                    .length;
                final tarefasPendentes = tarefas
                    .where((t) => t.status == 'pendente')
                    .length;
                final tarefasEmAndamento = tarefas
                    .where((t) => t.status == 'em andamento')
                    .length;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total de Tarefas: $totalTarefas'),
                        Text('Concluídas: $tarefasConcluidas'),
                        Text('Pendentes: $tarefasPendentes'),
                        Text('Em Andamento: $tarefasEmAndamento'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Tarefas por Propriedade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<List<Propriedade>>(
              stream: _firestoreService.getPropriedades(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }
                if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Nenhuma propriedade encontrada.');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final propriedade = snapshot.data![index];
                    return StreamBuilder<List<Tarefa>>(
                      stream: _firestoreService.getTarefas(propriedade.id),
                      builder: (context, tarefasSnapshot) {
                        if (tarefasSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingWidget();
                        }
                        final tarefas = tarefasSnapshot.data ?? [];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(propriedade.nome),
                            subtitle: Text('Tarefas: ${tarefas.length}'),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
