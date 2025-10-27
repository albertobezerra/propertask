import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:propertask/core/models/tarefa.dart';
import 'package:propertask/core/services/firestore_service.dart';
import 'package:propertask/core/utils/formatters.dart';
import 'package:propertask/widgets/loading_widget.dart';

class TarefaDetalheScreen extends StatelessWidget {
  final String tarefaId;

  const TarefaDetalheScreen({super.key, required this.tarefaId});

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Tarefa')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('propertask')
            .doc('tarefas')
            .collection('tarefas')
            .doc(tarefaId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          if (snapshot.hasError) {
            return Text('Erro: ${snapshot.error}');
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Text('Tarefa não encontrada.');
          }

          final tarefa = Tarefa.fromFirestore(snapshot.data!);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Título: ${tarefa.titulo}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text('Status: ${tarefa.status}'),
                Text('Criado em: ${Formatters.formatDate(tarefa.criadoEm)}'),
                Text('Responsável ID: ${tarefa.responsavelId}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
