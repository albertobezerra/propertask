import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/models/tarefa.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/services/firestore_service.dart';
import 'package:propertask/screen/tarefa_detalhe_screen.dart';
import 'package:propertask/widgets/custom_text_field.dart';
import 'package:propertask/widgets/loading_widget.dart';

class PropriedadeDetalheScreen extends StatefulWidget {
  final String propriedadeId;
  final String propriedadeNome;

  const PropriedadeDetalheScreen({
    super.key,
    required this.propriedadeId,
    required this.propriedadeNome,
  });

  @override
  _PropriedadeDetalheScreenState createState() =>
      _PropriedadeDetalheScreenState();
}

class _PropriedadeDetalheScreenState extends State<PropriedadeDetalheScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'todos';
  final FirestoreService _firestoreService = FirestoreService();

  void _adicionarTarefa(BuildContext context) {
    TextEditingController _tituloController = TextEditingController();
    final appState = Provider.of<AppState>(context, listen: false);
    final responsavelId = appState.user?.uid ?? '1HxCrQXAkseNJ8gtIS3PYVoCmmW2';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova Tarefa'),
        content: CustomTextField(
          controller: _tituloController,
          hintText: 'Título da tarefa',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_tituloController.text.isNotEmpty) {
                try {
                  final tarefa = Tarefa(
                    id: '',
                    titulo: _tituloController.text,
                    propriedadeId: widget.propriedadeId,
                    status: 'pendente',
                    responsavelId: responsavelId,
                    criadoEm: DateTime.now(),
                  );
                  await _firestoreService.addTarefa(tarefa);
                  debugPrint('✅ Tarefa adicionada: ${_tituloController.text}');
                  Navigator.pop(context);
                } catch (e) {
                  debugPrint('❌ Erro ao adicionar tarefa: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao adicionar tarefa: $e')),
                  );
                }
              }
            },
            child: const Text('Adicionar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.propriedadeNome)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _searchController,
                    hintText: 'Pesquisar tarefas',
                    prefixIcon: Icons.search,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(
                      value: 'pendente',
                      child: Text('Pendente'),
                    ),
                    DropdownMenuItem(
                      value: 'em andamento',
                      child: Text('Em Andamento'),
                    ),
                    DropdownMenuItem(
                      value: 'concluída',
                      child: Text('Concluída'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value ?? 'todos';
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Tarefa>>(
              stream: _firestoreService.getTarefas(widget.propriedadeId),
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

                final tarefas = snapshot.data!.where((tarefa) {
                  final titulo = tarefa.titulo.toLowerCase();
                  final statusMatch =
                      _statusFilter == 'todos' ||
                      tarefa.status == _statusFilter;
                  return titulo.contains(_searchQuery) && statusMatch;
                }).toList();

                return ListView.builder(
                  itemCount: tarefas.length,
                  itemBuilder: (context, index) {
                    var tarefa = tarefas[index];
                    return ListTile(
                      title: Text(tarefa.titulo),
                      subtitle: Text('Status: ${tarefa.status}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TarefaDetalheScreen(tarefaId: tarefa.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _adicionarTarefa(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
