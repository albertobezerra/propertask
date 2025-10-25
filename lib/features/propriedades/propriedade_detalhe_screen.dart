import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:propertask/features/tarefas/tarefa_detalhe_screen.dart';

class PropriedadeDetalheScreen extends StatefulWidget {
  final String propriedadeId;
  final String propriedadeNome;

  const PropriedadeDetalheScreen({
    super.key,
    required this.propriedadeId,
    required this.propriedadeNome,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PropriedadeDetalheScreenState createState() =>
      _PropriedadeDetalheScreenState();
}

class _PropriedadeDetalheScreenState extends State<PropriedadeDetalheScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get tarefas =>
      _firestore.collection('propertask').doc('tarefas').collection('tarefas');

  void _adicionarTarefa() async {
    TextEditingController tituloController = TextEditingController();
    String? selectedUsuario;

    try {
      final usuariosSnapshot = await _firestore
          .collection('propertask')
          .doc('usuarios')
          .collection('usuarios')
          .where('role', isEqualTo: 'colaborador')
          .get();

      final usuarios = usuariosSnapshot.docs;

      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Nova Tarefa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: InputDecoration(labelText: 'Título'),
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedUsuario,
                hint: Text('Atribuir a'),
                items: usuarios.map((u) {
                  return DropdownMenuItem(value: u.id, child: Text(u['nome']));
                }).toList(),
                onChanged: (val) {
                  selectedUsuario = val;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (tituloController.text.isNotEmpty &&
                    selectedUsuario != null) {
                  try {
                    final tarefaDoc = await tarefas.add({
                      'titulo': tituloController.text,
                      'status': 'pendente',
                      'propriedadeId': widget.propriedadeId,
                      'responsavelId': selectedUsuario,
                      'criadoEm': FieldValue.serverTimestamp(),
                    });
                    debugPrint(
                      '✅ Tarefa adicionada: ${tituloController.text} (ID: ${tarefaDoc.id})',
                    );
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  } catch (e) {
                    debugPrint('❌ Erro ao adicionar tarefa: $e');
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao adicionar tarefa: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Preencha todos os campos.')),
                  );
                }
              },
              child: Text('Adicionar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ Erro ao carregar usuários para tarefa: $e');
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar usuários: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'PropriedadeDetalheScreen: Iniciando build para ${widget.propriedadeId}',
    );
    return Scaffold(
      appBar: AppBar(title: Text('Propriedade: ${widget.propriedadeNome}')),
      body: StreamBuilder(
        stream: tarefas
            .where('propriedadeId', isEqualTo: widget.propriedadeId)
            .orderBy('criadoEm')
            .snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            debugPrint('PropriedadeDetalheScreen: Aguardando dados');
            return Center(child: CircularProgressIndicator());
          }

          final tarefas = snapshot.data.docs;

          if (tarefas.isEmpty) {
            debugPrint('PropriedadeDetalheScreen: Nenhuma tarefa encontrada');
            return Center(child: Text('Nenhuma tarefa cadastrada.'));
          }

          debugPrint(
            'PropriedadeDetalheScreen: ${tarefas.length} tarefas carregadas',
          );
          return ListView.builder(
            itemCount: tarefas.length,
            itemBuilder: (context, index) {
              final tarefa = tarefas[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ListTile(
                  title: Text(tarefa['titulo'] ?? 'Sem título'),
                  subtitle: Text('Status: ${tarefa['status'] ?? 'Sem status'}'),
                  trailing: Icon(Icons.check_circle_outline),
                  onTap: () {
                    debugPrint(
                      'Navegando para TarefaDetalheScreen: ${tarefa.id}',
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TarefaDetalheScreen(tarefaId: tarefa.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarTarefa,
        child: Icon(Icons.add_task),
      ),
    );
  }
}
