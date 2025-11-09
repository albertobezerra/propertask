import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';
import 'package:propertask/screen/tarefas/tarefa_detalhe_screen.dart';
import 'package:propertask/screen/tarefas/tarefa_form_screen.dart';
import 'package:propertask/widgets/app_drawer.dart';

class TarefasScreen extends StatefulWidget {
  const TarefasScreen({super.key});

  @override
  State<TarefasScreen> createState() => _TarefasScreenState();
}

class _TarefasScreenState extends State<TarefasScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Filtros em dropdown
  String _status = 'Todos'; // Todos, pendente, em_andamento, concluida
  String _tipo = 'Todos'; // Todos, limpeza, entrega, recolha, manutencao

  // Data do dia
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _inicioDia(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _fimExclusivo(DateTime d) =>
      _inicioDia(d).add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final cargo = Provider.of<AppState>(context).usuario?.cargo ?? 'LIMPEZA';
    final podeEditar = Permissions.podeGerenciarPropriedades(cargo);

    final inicioDia = _inicioDia(_selectedDate);
    final fimDiaExclusive = _fimExclusivo(_selectedDate);
    final fmtDia = DateFormat('dd/MM');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefas'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/tarefas'),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TarefaFormScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Nova tarefa'),
        ),
      ),
      body: Column(
        children: [
          // LINHA 1: BUSCA (80%) + DATA (20%)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  flex: 4, // ~80%
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar tarefa ou propriedade...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              tooltip: 'Limpar',
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1, // ~20%
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(fmtDia.format(_selectedDate)),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // LINHA 2: STATUS (50%) + TIPO (50%)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _status,
                    items: const [
                      DropdownMenuItem(
                        value: 'Todos',
                        child: Text('Todos', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'pendente',
                        child: Text(
                          'Pendente',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'em_andamento',
                        child: Text(
                          'Em andamento',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'concluida',
                        child: Text(
                          'Concluída',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'Todos'),
                    decoration: InputDecoration(
                      labelText: 'Status',
                      prefixIcon: const Icon(Icons.flag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _tipo,
                    items: const [
                      DropdownMenuItem(
                        value: 'Todos',
                        child: Text('Todos', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'limpeza',
                        child: Text('Limpeza', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'entrega',
                        child: Text('Entrega', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'recolha',
                        child: Text('Recolha', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'manutencao',
                        child: Text(
                          'Manutenção',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _tipo = v ?? 'Todos'),
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Lista
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
                  .where(
                    'data',
                    isLessThan: Timestamp.fromDate(fimDiaExclusive),
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhuma tarefa neste dia.'));
                }

                var docs = snapshot.data!.docs.toList();

                // Filtro de status (dropdown)
                if (_status != 'Todos') {
                  docs = docs
                      .where((d) => (d['status'] ?? 'pendente') == _status)
                      .toList();
                }

                // Filtro de tipo (dropdown)
                if (_tipo != 'Todos') {
                  docs = docs.where((d) => (d['tipo'] ?? '') == _tipo).toList();
                }

                // Filtro de busca
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final titulo = (d['titulo'] ?? '').toString().toLowerCase();
                    final prop = (d['propriedadeNome'] ?? '')
                        .toString()
                        .toLowerCase();
                    return titulo.contains(_searchQuery) ||
                        prop.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma tarefa atende aos filtros.'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final titulo = (data['titulo'] ?? 'Sem título').toString();
                    final status = (data['status'] ?? 'pendente').toString();
                    final tipo = (data['tipo'] ?? 'limpeza').toString();
                    final prop = (data['propriedadeNome'] ?? 'Sem propriedade')
                        .toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(status),
                          child: Text(
                            tipo.isNotEmpty ? tipo[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${_formatStatus(status)} • $prop'),
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
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
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
