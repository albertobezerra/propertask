import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:propertask/screen/tarefas/tarefa_detalhe_screen.dart';
import 'package:propertask/screen/tarefas/tarefa_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';

class TarefasScreen extends StatefulWidget {
  const TarefasScreen({super.key});

  @override
  State<TarefasScreen> createState() => _TarefasScreenState();
}

class _TarefasScreenState extends State<TarefasScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'todas';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cargo = Provider.of<AppState>(context).usuario?.cargo ?? 'LIMPEZA';
    final podeEditar = Permissions.podeGerenciarPropriedades(cargo);
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefas do Dia'),
        actions: [
          if (podeEditar)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TarefaFormScreen()),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // FILTROS
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar tarefa...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: [
                    const DropdownMenuItem(
                      value: 'todas',
                      child: Text('Todas'),
                    ),
                    const DropdownMenuItem(
                      value: 'pendente',
                      child: Text('Pendente'),
                    ),
                    const DropdownMenuItem(
                      value: 'em_andamento',
                      child: Text('Em Andamento'),
                    ),
                    const DropdownMenuItem(
                      value: 'concluida',
                      child: Text('Concluída'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v!),
                ),
              ],
            ),
          ),
          // LISTA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('propertask')
                  .doc('tarefas')
                  .collection('tarefas')
                  .where(
                    'data',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia),
                  )
                  .where('data', isLessThan: Timestamp.fromDate(fimDia))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhuma tarefa hoje.'));
                }

                var docs = snapshot.data!.docs;

                // FILTRO DE STATUS
                if (_statusFilter != 'todas') {
                  docs = docs
                      .where(
                        (d) => (d['status'] ?? 'pendente') == _statusFilter,
                      )
                      .toList();
                }

                // FILTRO DE BUSCA
                docs = docs.where((d) {
                  final titulo = (d['titulo'] ?? '').toString().toLowerCase();
                  return titulo.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final titulo = data['titulo'] ?? 'Sem título';
                    final status = data['status'] ?? 'pendente';
                    final tipo = data['tipo'] ?? 'limpeza';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(status),
                          child: Text(
                            tipo[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${_formatStatus(status)} • ${data['propriedadeNome'] ?? 'Sem propriedade'}',
                        ),
                        trailing: podeEditar
                            ? PopupMenuButton(
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TarefaFormScreen(tarefa: doc),
                                      ),
                                    );
                                  } else if (v == 'delete') {
                                    _deleteTarefa(context, doc.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Excluir'),
                                  ),
                                ],
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TarefaDetalheScreen(tarefaId: doc.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'concluida':
        return Colors.green;
      case 'em_andamento':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'em_andamento':
        return 'Em Andamento';
      case 'concluida':
        return 'Concluída';
      default:
        return status;
    }
  }

  void _deleteTarefa(BuildContext context, String id) {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir?'),
        content: const Text('Esta tarefa será removida permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('propertask')
                    .doc('tarefas')
                    .collection('tarefas')
                    .doc(id)
                    .delete();

                if (!mounted) return;

                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Tarefa excluída')),
                );
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir: $e'),
                      backgroundColor: Colors.red,
                    ),
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
}
