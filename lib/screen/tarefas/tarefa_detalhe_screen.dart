import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';

class TarefaDetalheScreen extends StatelessWidget {
  final String tarefaId;

  const TarefaDetalheScreen({super.key, required this.tarefaId});

  @override
  Widget build(BuildContext context) {
    final cargo = Provider.of<AppState>(context).usuario?.cargo ?? 'LIMPEZA';
    final podeEditar = [
      'DEV',
      'CEO',
      'COORDENADOR',
      'SUPERVISOR',
    ].contains(cargo);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da Tarefa')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('propertask')
            .doc('tarefas')
            .collection('tarefas')
            .doc(tarefaId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _infoRow('Título', data['titulo']),
              _infoRow('Tipo', data['tipo']?.toString().toUpperCase()),
              _infoRow('Propriedade', data['propriedadeNome']),
              _infoRow('Status', _formatStatus(data['status'])),
              _infoRow('Data', _formatDate(data['data'])),
              if (data['observacoes'] != null)
                _infoRow('Observações', data['observacoes']),
              const SizedBox(height: 20),
              if (podeEditar)
                ElevatedButton(
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final novoStatus = data['status'] == 'concluida'
                        ? 'pendente'
                        : 'concluida';

                    try {
                      await snapshot.data!.reference.update({
                        'status': novoStatus,
                        'concluidaEm': novoStatus == 'concluida'
                            ? FieldValue.serverTimestamp()
                            : null,
                      });

                      if (!context.mounted) return;

                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Status alterado para $novoStatus'),
                        ),
                      );
                    } catch (e) {
                      if (context.mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Erro ao atualizar: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    data['status'] == 'concluida'
                        ? 'Reabrir'
                        : 'Concluir Tarefa',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? '—')),
        ],
      ),
    );
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'em_andamento':
        return 'Em Andamento';
      case 'concluida':
        return 'Concluída';
      default:
        return status ?? 'Pendente';
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '—';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
