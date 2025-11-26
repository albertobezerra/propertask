// lib/widgets/tarefa_card.dart
import 'package:flutter/material.dart';
import 'package:propertask/core/models/tarefa.dart';
import 'package:propertask/core/utils/formatters.dart';
import 'package:propertask/core/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';

class TarefaCard extends StatelessWidget {
  final Tarefa tarefa;
  final bool podeEditar;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TarefaCard({
    super.key,
    required this.tarefa,
    this.podeEditar = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = tarefa.status == 'concluida' ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            tarefa.tipo[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          tarefa.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${tarefa.tipo.toUpperCase()} • ${Formatters.formatDate(tarefa.data)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: podeEditar
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed:
                        onEdit ?? () => _showNotImplemented(context, 'Editar'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Tarefa?'),
        content: Text('Tem certeza que deseja excluir "${tarefa.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              navigator.pop();

              try {
                final empresaId = Provider.of<AppState>(
                  context,
                  listen: false,
                ).empresaId!;
                await FirestoreService(
                  empresaId: empresaId,
                ).deleteTarefa(tarefa.id);

                if (!context.mounted) return;

                if (onDelete != null) onDelete!();

                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Tarefa excluída com sucesso')),
                );
              } catch (e) {
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Erro ao excluir: $e')),
                  );
                }
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNotImplemented(BuildContext context, String action) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$action não implementado ainda')));
  }
}
