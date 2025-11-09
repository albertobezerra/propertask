import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertask/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TarefaFormScreen extends StatefulWidget {
  final DocumentSnapshot? tarefa;

  const TarefaFormScreen({super.key, this.tarefa});

  @override
  State<TarefaFormScreen> createState() => _TarefaFormScreenState();
}

class _TarefaFormScreenState extends State<TarefaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _observacoes;

  String _tipo = 'limpeza';
  String _status = 'pendente';
  String? _propriedadeId, _responsavelId;
  DateTime _data = DateTime.now();

  // Sofá-cama
  bool _propTemSofaCama = false; // vindo da propriedade
  bool _fazerSofaCama = true; // controle do formulário quando aplicável

  @override
  void initState() {
    super.initState();
    final data = widget.tarefa?.data() as Map<String, dynamic>? ?? {};
    _observacoes = TextEditingController(
      text: (data['observacoes'] ?? '').toString(),
    );
    _tipo = (data['tipo'] ?? 'limpeza').toString();
    _status = (data['status'] ?? 'pendente').toString();
    _propriedadeId = data['propriedadeId'] as String?;
    _responsavelId = data['responsavelId'] as String?;
    _data = data['data'] != null
        ? (data['data'] as Timestamp).toDate()
        : DateTime.now();
    _fazerSofaCama = (data['fazerSofaCama'] ?? true) == true;

    // Se já veio com propriedade, buscar info de sofá-cama
    if (_propriedadeId != null) {
      _loadPropriedadeSofaCama(_propriedadeId!);
    }
  }

  Future<void> _loadPropriedadeSofaCama(String propId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('propertask')
          .doc('propriedades')
          .collection('propriedades')
          .doc(propId)
          .get();
      final d = snap.data() ?? {};
      final tem = (d['sofaCama'] ?? false) == true;
      setState(() {
        _propTemSofaCama = tem;
        // Quando a prop permite, manter marcado por padrão
        if (tem && widget.tarefa == null) _fazerSofaCama = true;
      });
    } catch (_) {
      setState(() {
        _propTemSofaCama = false;
      });
    }
  }

  @override
  void dispose() {
    _observacoes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Locale do app (para datas e calendário)
    final locale = Localizations.localeOf(context).toString();
    final dataFmt = DateFormat('dd/MM/yyyy', locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tarefa == null ? 'Nova tarefa' : 'Editar tarefa'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tipo
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              items: const [
                DropdownMenuItem(value: 'limpeza', child: Text('LIMPEZA')),
                DropdownMenuItem(value: 'entrega', child: Text('ENTREGA')),
                DropdownMenuItem(value: 'recolha', child: Text('RECOLHA')),
                DropdownMenuItem(
                  value: 'manutencao',
                  child: Text('MANUTENÇÃO'),
                ),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 16),

            // Propriedade
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('propertask')
                  .doc('propriedades')
                  .collection('propriedades')
                  .orderBy('nome')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('Carregando propriedades...');
                }
                final props = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  initialValue: _propriedadeId,
                  hint: const Text('Selecione a propriedade'),
                  items: props.map((p) {
                    final nome = (p['nome'] ?? 'Sem nome').toString();
                    return DropdownMenuItem(value: p.id, child: Text(nome));
                  }).toList(),
                  onChanged: (v) {
                    setState(() => _propriedadeId = v);
                    if (v != null) _loadPropriedadeSofaCama(v);
                  },
                  validator: (v) => v == null ? 'Obrigatório' : null,
                );
              },
            ),
            const SizedBox(height: 8),

            // Sofá‑cama (aparece só se a propriedade tiver possibilidade)
            if (_propTemSofaCama) ...[
              CheckboxListTile(
                value: _fazerSofaCama,
                onChanged: (v) => setState(() => _fazerSofaCama = v ?? true),
                title: const Text('Sofá‑cama necessário'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
            ],

            // Responsável
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('propertask')
                  .doc('usuarios')
                  .collection('usuarios')
                  .orderBy('nome')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('Carregando usuários...');
                }
                final users = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  initialValue: _responsavelId,
                  hint: const Text('Atribuir a'),
                  items: users.map((u) {
                    final nome = (u['nome'] ?? 'Sem nome').toString();
                    return DropdownMenuItem(value: u.id, child: Text(nome));
                  }).toList(),
                  onChanged: (v) => setState(() => _responsavelId = v),
                  validator: (v) => v == null ? 'Obrigatório' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // Data (dd/MM/yyyy com zero à esquerda e calendário no idioma do telefone)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('data'),
              subtitle: Text(dataFmt.format(_data)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _data,
                  firstDate: DateTime.now().subtract(const Duration(days: 0)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  // Usa o locale do app (por padrão herdado do contexto)
                );
                if (picked != null) setState(() => _data = picked);
              },
            ),
            const SizedBox(height: 16),

            // Observações (inicial minúscula como solicitado)
            TextFormField(
              controller: _observacoes,
              decoration: const InputDecoration(labelText: 'observações'),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Botão salvar
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                if (_propriedadeId == null || _responsavelId == null) return;

                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                // Buscar nome da propriedade
                final propDoc = await FirebaseFirestore.instance
                    .collection('propertask')
                    .doc('propriedades')
                    .collection('propriedades')
                    .doc(_propriedadeId!)
                    .get();
                final propNome = (propDoc['nome'] ?? 'Propriedade').toString();

                // Gerar um título automaticamente (campo não exibido)
                final tipoNome =
                    {
                      'limpeza': 'Limpeza',
                      'entrega': 'Entrega',
                      'recolha': 'Recolha',
                      'manutencao': 'Manutenção',
                    }[_tipo] ??
                    _tipo;
                final tituloAuto = '$tipoNome • ${dataFmt.format(_data)}';

                final ref = FirebaseFirestore.instance
                    .collection('propertask')
                    .doc('tarefas')
                    .collection('tarefas');

                final tarefaData = {
                  'titulo': tituloAuto, // gerado automaticamente
                  'tipo': _tipo,
                  'propriedadeId': _propriedadeId,
                  'propriedadeNome': propNome,
                  'responsavelId': _responsavelId,
                  'status': _status,
                  'data': Timestamp.fromDate(_data),
                  'observacoes': _observacoes.text.trim().isEmpty
                      ? null
                      : _observacoes.text.trim(),
                  // grava sofá-cama apenas se a propriedade permitir
                  'fazerSofaCama': _propTemSofaCama ? _fazerSofaCama : null,
                };

                try {
                  if (widget.tarefa == null) {
                    await ref.add(tarefaData);
                    _showLocalNotification(tituloAuto, propNome);
                  } else {
                    await widget.tarefa!.reference.update(tarefaData);
                  }
                  if (!mounted) return;
                  navigator.pop();
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Erro ao salvar tarefa: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(widget.tarefa == null ? 'Criar tarefa' : 'Salvar'),
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
      'Nova tarefa atribuída',
      'Você foi atribuído a: $titulo em $propriedade',
      platform,
    );
  }
}
