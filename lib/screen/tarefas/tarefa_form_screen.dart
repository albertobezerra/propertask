import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';

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

  bool _propTemSofaCama = false;
  bool _fazerSofaCama = true;

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

    if (_propriedadeId != null) {
      _loadPropriedadeSofaCama(_propriedadeId!);
    }
  }

  Future<void> _loadPropriedadeSofaCama(String propId) async {
    try {
      final empresaId = Provider.of<AppState>(
        context,
        listen: false,
      ).empresaId!;
      final snap = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(empresaId)
          .collection('propriedades')
          .doc(propId)
          .get();
      final d = snap.data() ?? {};
      final tem = (d['sofaCama'] ?? false) == true;
      setState(() {
        _propTemSofaCama = tem;
        if (tem && widget.tarefa == null) _fazerSofaCama = true;
      });
    } catch (_) {
      setState(() => _propTemSofaCama = false);
    }
  }

  @override
  void dispose() {
    _observacoes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final usuario = Provider.of<AppState>(context).usuario;
    final empresaId = Provider.of<AppState>(context).empresaId!;
    final cargo = usuario?.cargo ?? 'LIMPEZA';
    final podeAtribuir = Permissions.cargoFromString(cargo) != Cargo.limpeza;
    final locale = Localizations.localeOf(context).toString();
    final dataFmt = DateFormat('dd/MM/yyyy', locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tarefa == null ? 'Nova tarefa' : 'Editar tarefa'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              items: const [
                DropdownMenuItem(value: 'limpeza', child: Text('Limpeza')),
                DropdownMenuItem(value: 'entrega', child: Text('Entrega')),
                DropdownMenuItem(value: 'recolha', child: Text('Recolha')),
                DropdownMenuItem(
                  value: 'manutencao',
                  child: Text('Manutenção'),
                ),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 16),

            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('empresas')
                  .doc(empresaId)
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
                  items: props
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p['nome'] ?? 'Sem nome'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => _propriedadeId = v);
                    if (v != null) _loadPropriedadeSofaCama(v);
                  },
                  validator: (v) => v == null ? 'Obrigatório' : null,
                  decoration: const InputDecoration(labelText: 'Propriedade'),
                );
              },
            ),
            const SizedBox(height: 8),

            if (_propTemSofaCama) ...[
              CheckboxListTile(
                value: _fazerSofaCama,
                onChanged: (v) => setState(() => _fazerSofaCama = v ?? true),
                title: const Text('Sofá-cama necessário'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
            ],

            if (podeAtribuir)
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('empresas')
                    .doc(empresaId)
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
                    items: users
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(u['nome'] ?? 'Sem nome'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _responsavelId = v),
                    validator: (v) => v == null ? 'Obrigatório' : null,
                    decoration: const InputDecoration(
                      labelText: 'Funcionário responsável',
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data'),
              subtitle: Text(dataFmt.format(_data)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _data,
                  firstDate: DateTime.now().subtract(const Duration(days: 90)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _data = picked);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _observacoes,
              decoration: const InputDecoration(labelText: 'Observações'),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _onSalvarPressed,
              child: Text(
                widget.tarefa == null ? 'Criar tarefa' : 'Salvar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSalvarPressed() async {
    if (!_formKey.currentState!.validate()) return;
    if (_propriedadeId == null ||
        (_responsavelId == null &&
            Permissions.cargoFromString(
                  Provider.of<AppState>(context, listen: false).usuario!.cargo,
                ) !=
                Cargo.limpeza)) {
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final empresaId = Provider.of<AppState>(
        context,
        listen: false,
      ).empresaId!;

      // Buscar nome da propriedade para salvar
      final propDoc = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(empresaId)
          .collection('propriedades')
          .doc(_propriedadeId!)
          .get();
      final propNome = (propDoc['nome'] ?? 'Propriedade').toString();

      // Buscar nome do responsável (para gestores)
      String? responsavelNome;
      if (_responsavelId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('empresas')
            .doc(empresaId)
            .collection('usuarios')
            .doc(_responsavelId!)
            .get();
        responsavelNome = (userDoc['nome'] ?? 'Funcionário').toString();
      }

      final dataFmt = DateFormat('dd/MM/yyyy');
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
          .collection('empresas')
          .doc(empresaId)
          .collection('tarefas');

      final base = {
        'titulo': tituloAuto,
        'tipo': _tipo,
        'propriedadeId': _propriedadeId,
        'propriedadeNome': propNome,
        'status': _status,
        'data': Timestamp.fromDate(_data),
        'observacoes': _observacoes.text.trim().isEmpty
            ? null
            : _observacoes.text.trim(),
        'fazerSofaCama': _propTemSofaCama ? _fazerSofaCama : null,
        if (_responsavelId != null) 'responsavelId': _responsavelId,
        if (responsavelNome != null) 'responsavelNome': responsavelNome,
      };

      if (widget.tarefa == null) {
        await ref.add({...base, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await widget.tarefa!.reference.update({
          ...base,
          'updatedAt': FieldValue.serverTimestamp(),
        });
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
  }
}
