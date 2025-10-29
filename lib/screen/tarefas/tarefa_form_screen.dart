import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:propertask/main.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TarefaFormScreen extends StatefulWidget {
  final DocumentSnapshot? tarefa;

  const TarefaFormScreen({super.key, this.tarefa});

  @override
  State<TarefaFormScreen> createState() => _TarefaFormScreenState();
}

class _TarefaFormScreenState extends State<TarefaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titulo, _observacoes;
  String _tipo = 'limpeza';
  String _status = 'pendente';
  String? _propriedadeId, _responsavelId;
  DateTime _data = DateTime.now();

  @override
  void initState() {
    super.initState();
    final data = widget.tarefa?.data() as Map<String, dynamic>? ?? {};
    _titulo = TextEditingController(text: data['titulo'] ?? '');
    _observacoes = TextEditingController(text: data['observacoes'] ?? '');
    _tipo = data['tipo'] ?? 'limpeza';
    _status = data['status'] ?? 'pendente';
    _propriedadeId = data['propriedadeId'];
    _responsavelId = data['responsavelId'];
    _data = data['data'] != null
        ? (data['data'] as Timestamp).toDate()
        : DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tarefa == null ? 'Nova Tarefa' : 'Editar Tarefa'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(labelText: 'Título *'),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipo,
              items: ['limpeza', 'entrega', 'recolha', 'manutencao']
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _tipo = v!),
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 16),
            // PROPRIEDADE
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('propertask')
                  .doc('propriedades')
                  .collection('propriedades')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Text('Carregando propriedades...');
                final props = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _propriedadeId,
                  hint: const Text('Selecione a propriedade'),
                  items: props.map((p) {
                    final nome = (p['nome'] ?? 'Sem nome');
                    return DropdownMenuItem(value: p.id, child: Text(nome));
                  }).toList(),
                  onChanged: (v) => setState(() => _propriedadeId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            // RESPONSÁVEL
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('propertask')
                  .doc('usuarios')
                  .collection('usuarios')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Text('Carregando usuários...');
                final users = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _responsavelId,
                  hint: const Text('Atribuir a'),
                  items: users.map((u) {
                    final nome = (u['nome'] ?? 'Sem nome');
                    return DropdownMenuItem(value: u.id, child: Text(nome));
                  }).toList(),
                  onChanged: (v) => setState(() => _responsavelId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Data'),
              subtitle: Text('${_data.day}/${_data.month}/${_data.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _data,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _data = picked);
              },
            ),
            TextFormField(
              controller: _observacoes,
              decoration: const InputDecoration(labelText: 'Observações'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() &&
                    _propriedadeId != null &&
                    _responsavelId != null) {
                  final ref = FirebaseFirestore.instance
                      .collection('propertask')
                      .doc('tarefas')
                      .collection('tarefas');
                  final propDoc = await FirebaseFirestore.instance
                      .collection('propertask')
                      .doc('propriedades')
                      .collection('propriedades')
                      .doc(_propriedadeId!)
                      .get();
                  final propNome = propDoc['nome'] ?? 'Propriedade';

                  final tarefaData = {
                    'titulo': _titulo.text,
                    'tipo': _tipo,
                    'propriedadeId': _propriedadeId,
                    'propriedadeNome': propNome,
                    'responsavelId': _responsavelId,
                    'status': _status,
                    'data': Timestamp.fromDate(_data),
                    'observacoes': _observacoes.text.isEmpty
                        ? null
                        : _observacoes.text,
                  };

                  if (widget.tarefa == null) {
                    await ref.add(tarefaData);
                    _showLocalNotification(_titulo.text, propNome);
                  } else {
                    await widget.tarefa!.reference.update(tarefaData);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(widget.tarefa == null ? 'Criar Tarefa' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocalNotification(String titulo, String propriedade) async {
    const android = AndroidNotificationDetails(
      'tarefas_channel',
      'Tarefas',
      channelDescription: 'Notificações de novas tarefas',
      importance: Importance.high,
      priority: Priority.high,
    );
    const platform = NotificationDetails(android: android);
    await notifications.show(
      0,
      'Nova Tarefa Atribuída',
      'Você foi atribuído a: $titulo em $propriedade',
      platform,
    );
  }
}
