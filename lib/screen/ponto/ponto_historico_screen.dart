import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';
import 'package:intl/intl.dart';

class PontoHistoricoScreen extends StatefulWidget {
  const PontoHistoricoScreen({super.key});

  @override
  State<PontoHistoricoScreen> createState() => _PontoHistoricoScreenState();
}

class _PontoHistoricoScreenState extends State<PontoHistoricoScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final cargo = Provider.of<AppState>(context).usuario?.cargo ?? 'LIMPEZA';
    final podeEditar = Permissions.podeGerenciarUsuarios(cargo);

    final inicio = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final fim = inicio.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Ponto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('propertask')
            .doc('ponto')
            .collection('registros')
            .where(
              'horarioReal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
            )
            .where('horarioReal', isLessThan: Timestamp.fromDate(fim))
            .orderBy('horarioReal', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum registro neste dia.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snapshot.data!.docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final tipo = data['tipo'] as String;
              final horarioReal = (data['horarioReal'] as Timestamp).toDate();
              final horarioArredondado =
                  (data['horarioArredondado'] as Timestamp).toDate();
              final usuarioId = data['usuarioId'] as String;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('propertask')
                    .doc('usuarios')
                    .collection('usuarios')
                    .doc(usuarioId)
                    .get(),
                builder: (context, userSnap) {
                  final nome = userSnap.data?.get('nome') ?? 'Desconhecido';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tipo == 'entrada'
                            ? Colors.green
                            : Colors.red,
                        child: Text(
                          tipo == 'entrada' ? 'E' : 'S',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('HH:mm').format(horarioReal)} → ${DateFormat('HH:mm').format(horarioArredondado)}',
                          ),
                          if (data['observacao'] != null)
                            Text(
                              data['observacao'],
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      trailing: podeEditar
                          ? PopupMenuButton(
                              onSelected: (v) {
                                if (v == 'edit')
                                  _editarObservacao(context, doc);
                                if (v == 'delete')
                                  _excluirPonto(context, doc.id);
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
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _editarObservacao(BuildContext context, DocumentSnapshot doc) {
    final controller = TextEditingController(text: doc['observacao'] ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Observação'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Opcional'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await doc.reference.update({
                'observacao': controller.text.isEmpty ? null : controller.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _excluirPonto(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir?'),
        content: const Text('Este registro será removido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('propertask')
                  .doc('ponto')
                  .collection('registros')
                  .doc(id)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
