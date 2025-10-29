import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PropriedadeFormScreen extends StatefulWidget {
  final DocumentSnapshot? propriedade;

  const PropriedadeFormScreen({super.key, this.propriedade});

  @override
  State<PropriedadeFormScreen> createState() => _PropriedadeFormScreenState();
}

class _PropriedadeFormScreenState extends State<PropriedadeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nome,
      _endereco,
      _acesso,
      _codigo,
      _lockbox,
      _tipologia;
  String _tipoAcesso = 'chave';

  @override
  void initState() {
    super.initState();
    final data = widget.propriedade?.data() as Map<String, dynamic>? ?? {};
    _nome = TextEditingController(text: data['nome'] ?? '');
    _endereco = TextEditingController(text: data['endereco'] ?? '');
    _acesso = TextEditingController(text: data['acesso'] ?? '');
    _codigo = TextEditingController(text: data['codigoAcesso'] ?? '');
    _lockbox = TextEditingController(text: data['lockboxLocal'] ?? '');
    _tipologia = TextEditingController(text: data['tipologia'] ?? 'T1');
    _tipoAcesso = data['acesso'] ?? 'chave';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propriedade == null ? 'Nova Propriedade' : 'Editar'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome *'),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            TextFormField(
              controller: _endereco,
              decoration: const InputDecoration(
                labelText: 'Endereço completo *',
              ),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipoAcesso,
              items: ['chave', 'codigo', 'lockbox']
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _tipoAcesso = v!),
              decoration: const InputDecoration(labelText: 'Tipo de acesso'),
            ),
            if (_tipoAcesso == 'codigo')
              TextFormField(
                controller: _codigo,
                decoration: const InputDecoration(
                  labelText: 'Código de acesso',
                ),
              ),
            if (_tipoAcesso == 'lockbox')
              TextFormField(
                controller: _lockbox,
                decoration: const InputDecoration(
                  labelText: 'Local do lockbox',
                ),
              ),
            TextFormField(
              controller: _tipologia,
              decoration: const InputDecoration(
                labelText: 'Tipologia (ex: T1, T2)',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final data = {
                    'nome': _nome.text,
                    'endereco': _endereco.text,
                    'acesso': _tipoAcesso,
                    'codigoAcesso': _codigo.text.isEmpty ? null : _codigo.text,
                    'lockboxLocal': _lockbox.text.isEmpty
                        ? null
                        : _lockbox.text,
                    'tipologia': _tipologia.text,
                    'fotos': [], // futuro
                  };

                  if (widget.propriedade == null) {
                    await FirebaseFirestore.instance
                        .collection('propertask')
                        .doc('propriedades')
                        .collection('propriedades')
                        .add(data);
                  } else {
                    await widget.propriedade!.reference.update(data);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(widget.propriedade == null ? 'Adicionar' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
