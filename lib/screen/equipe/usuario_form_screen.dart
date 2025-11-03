import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class UsuarioFormScreen extends StatefulWidget {
  final DocumentSnapshot? usuario;

  const UsuarioFormScreen({super.key, this.usuario});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nome, _email, _senha;
  String _cargo = 'LIMPEZA';
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    final data = widget.usuario?.data() as Map<String, dynamic>? ?? {};
    _nome = TextEditingController(text: data['nome'] ?? '');
    _email = TextEditingController(text: data['email'] ?? '');
    _senha = TextEditingController();
    _cargo = data['cargo'] ?? 'LIMPEZA';
    _ativo = data['ativo'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.usuario != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Funcionário' : 'Novo Funcionário'),
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
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            if (!isEdit)
              TextFormField(
                controller: _senha,
                decoration: const InputDecoration(labelText: 'Senha *'),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _cargo,
              items: [
                'DEV',
                'CEO',
                'COORDENADOR',
                'SUPERVISOR',
                'LIMPEZA',
                'LAVANDERIA',
                'MOTORISTA',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _cargo = v!),
              decoration: const InputDecoration(labelText: 'Cargo'),
            ),
            SwitchListTile(
              title: const Text('Ativo'),
              value: _ativo,
              onChanged: (v) => setState(() => _ativo = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  try {
                    final usuariosRef = FirebaseFirestore.instance
                        .collection('propertask')
                        .doc('usuarios')
                        .collection('usuarios');

                    if (!isEdit) {
                      final cred = await auth.FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                            email: _email.text,
                            password: _senha.text,
                          );
                      await usuariosRef.doc(cred.user!.uid).set({
                        'nome': _nome.text,
                        'email': _email.text,
                        'cargo': _cargo,
                        'ativo': _ativo,
                      });
                    } else {
                      await widget.usuario!.reference.update({
                        'nome': _nome.text,
                        'email': _email.text,
                        'cargo': _cargo,
                        'ativo': _ativo,
                      });
                    }

                    if (!mounted) return;
                    navigator.pop();
                  } catch (e) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Erro: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(isEdit ? 'Salvar' : 'Criar Funcionário'),
            ),
          ],
        ),
      ),
    );
  }
}
