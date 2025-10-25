import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TarefaDetalheScreen extends StatefulWidget {
  final String tarefaId;

  const TarefaDetalheScreen({super.key, required this.tarefaId});

  @override
  // ignore: library_private_types_in_public_api
  _TarefaDetalheScreenState createState() => _TarefaDetalheScreenState();
}

class _TarefaDetalheScreenState extends State<TarefaDetalheScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _checkItemController = TextEditingController();

  CollectionReference get tarefas =>
      _firestore.collection('propertask').doc('tarefas').collection('tarefas');

  void _adicionarCheckItem(String tarefaId) async {
    if (_checkItemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O item do checklist não pode estar vazio.')),
      );
      return;
    }
    try {
      await tarefas.doc(tarefaId).update({
        'checklist': FieldValue.arrayUnion([
          {'titulo': _checkItemController.text, 'feito': false},
        ]),
      });
      debugPrint(
        '✅ Item de checklist adicionado: ${_checkItemController.text}',
      );
      _checkItemController.clear();
    } catch (e) {
      debugPrint('❌ Erro ao adicionar item de checklist: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar item de checklist: $e')),
      );
    }
  }

  void _atualizarStatus(String status) async {
    try {
      await tarefas.doc(widget.tarefaId).update({'status': status});
      debugPrint('✅ Status atualizado para: $status');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar status: $e');
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao atualizar status: $e')));
    }
  }

  void _toggleCheckItem(int index, List<dynamic> checklist) async {
    try {
      bool current = checklist[index]['feito'];
      checklist[index]['feito'] = !current;
      await tarefas.doc(widget.tarefaId).update({'checklist': checklist});
      debugPrint('✅ Item de checklist atualizado: index $index');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar item de checklist: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar item de checklist: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('TarefaDetalheScreen: Iniciando build para ${widget.tarefaId}');
    return Scaffold(
      appBar: AppBar(title: Text('Detalhes da Tarefa')),
      body: StreamBuilder(
        stream: tarefas.doc(widget.tarefaId).snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            debugPrint('TarefaDetalheScreen: Aguardando dados');
            return Center(child: CircularProgressIndicator());
          }

          final tarefa = snapshot.data;
          List<dynamic> checklist = tarefa['checklist'] ?? [];

          debugPrint(
            'TarefaDetalheScreen: Tarefa carregada: ${tarefa['titulo']}',
          );
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Título: ${tarefa['titulo'] ?? 'Sem título'}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                DropdownButton<String>(
                  value: tarefa['status'],
                  items: ['pendente', 'em andamento', 'concluída']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) _atualizarStatus(val);
                  },
                ),
                SizedBox(height: 20),
                Text(
                  'Checklist:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: checklist.length,
                    itemBuilder: (context, index) {
                      final item = checklist[index];
                      return CheckboxListTile(
                        title: Text(item['titulo'] ?? 'Sem título'),
                        value: item['feito'] ?? false,
                        onChanged: (_) => _toggleCheckItem(index, checklist),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _checkItemController,
                        decoration: InputDecoration(
                          hintText: 'Novo item do checklist',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => _adicionarCheckItem(widget.tarefaId),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
