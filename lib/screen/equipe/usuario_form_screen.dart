// lib/screen/equipe/usuario_form_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class UsuarioFormScreen extends StatefulWidget {
  final DocumentSnapshot? usuario;
  final String adminEmail;
  final String adminPassword;

  const UsuarioFormScreen({
    super.key,
    this.usuario,
    required this.adminEmail,
    required this.adminPassword,
  });

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nome, _email;
  String _cargo = 'LIMPEZA';
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    final data = widget.usuario?.data() as Map<String, dynamic>? ?? {};
    _nome = TextEditingController(text: data['nome'] ?? '');
    _email = TextEditingController(text: data['email'] ?? '');
    _cargo = data['cargo'] ?? 'LIMPEZA';
    _ativo = data['ativo'] != false;
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.usuario != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Funcionário' : 'Convidar Funcionário'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome completo *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v!.trim().isEmpty ? 'Digite o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail *',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (v) => v!.contains('@') ? null : 'E-mail inválido',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _cargo,
              items:
                  const [
                        'LIMPEZA',
                        'LAVANDERIA',
                        'MOTORISTA',
                        'SUPERVISOR',
                        'COORDENADOR',
                        'CEO',
                        'DEV',
                        'RH',
                      ]
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(_formatCargoStatic(c)),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _cargo = v!),
              decoration: const InputDecoration(
                labelText: 'Cargo',
                prefixIcon: Icon(Icons.work),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('Status do Usuário'),
                subtitle: Text(
                  _ativo ? 'Ativo (pode logar)' : 'Inativo (bloqueado)',
                ),
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: Text(isEdit ? 'Salvar Alterações' : 'Enviar Convite'),
              onPressed: () => _salvar(context, isEdit),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCargoStatic(String cargo) {
    const map = {
      'DEV': 'Desenvolvedor',
      'CEO': 'CEO',
      'COORDENADOR': 'Coordenador',
      'SUPERVISOR': 'Supervisor',
      'LIMPEZA': 'Limpeza',
      'LAVANDERIA': 'Lavanderia',
      'MOTORISTA': 'Motorista',
      'RH': 'RH',
    };
    return map[cargo] ?? cargo;
  }

  String _gerarSenhaTemporaria() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(7);
  }

  Future<void> _salvar(BuildContext context, bool isEdit) async {
    if (!_formKey.currentState!.validate()) return;

    // Capture as dependências do context antes dos awaits
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final usuariosRef = FirebaseFirestore.instance
          .collection('propertask')
          .doc('usuarios')
          .collection('usuarios');

      if (!isEdit) {
        final tempPassword = _gerarSenhaTemporaria();

        // App secundária para evitar troca de sessão
        final String appName =
            'invite-${DateTime.now().microsecondsSinceEpoch}';
        final FirebaseApp secondaryApp = await Firebase.initializeApp(
          name: appName,
          options: Firebase.app().options,
        );

        try {
          final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(
            app: secondaryApp,
          );

          final cred = await secondaryAuth.createUserWithEmailAndPassword(
            email: _email.text.trim(),
            password: tempPassword,
          );

          final String novoUserId = cred.user!.uid;

          await usuariosRef.doc(novoUserId).set({
            'nome': _nome.text.trim(),
            'email': _email.text.trim(),
            'cargo': _cargo,
            'ativo': _ativo,
            'criadoPor': widget.adminEmail,
            'criadoEm': FieldValue.serverTimestamp(),
          });

          await secondaryAuth.sendPasswordResetEmail(email: _email.text.trim());
        } finally {
          await secondaryApp.delete();
        }

        if (!context.mounted) return; // guarda o uso do context

        messenger.showSnackBar(
          SnackBar(
            content: Text('Convite enviado para ${_email.text}!'),
            backgroundColor: Colors.green,
          ),
        );

        navigator.pop(true);
      } else {
        await widget.usuario!.reference.update({
          'nome': _nome.text.trim(),
          'email': _email.text.trim(),
          'cargo': _cargo,
          'ativo': _ativo,
        });

        if (!context.mounted) return;

        messenger.showSnackBar(const SnackBar(content: Text('Atualizado!')));

        navigator.pop(true);
      }
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro de autenticação: ${e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
