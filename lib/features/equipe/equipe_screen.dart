import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EquipeScreen extends StatefulWidget {
  const EquipeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EquipeScreenState createState() => _EquipeScreenState();
}

class _EquipeScreenState extends State<EquipeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get usuarios => _firestore
      .collection('propertask')
      .doc('usuarios')
      .collection('usuarios');

  void _adicionarColaborador() {
    TextEditingController nomeController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController senhaController = TextEditingController();
    String role = 'colaborador';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Adicionar Colaborador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Senha'),
            ),
            DropdownButtonFormField<String>(
              initialValue: role,
              items: [
                DropdownMenuItem(
                  value: 'colaborador',
                  child: Text('Colaborador'),
                ),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (val) {
                if (val != null) role = val;
              },
              decoration: InputDecoration(labelText: 'Cargo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (nomeController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  senhaController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Preencha todos os campos.')),
                );
                return;
              }

              try {
                UserCredential userCred = await _auth
                    .createUserWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: senhaController.text.trim(),
                    );
                String uid = userCred.user!.uid;

                await usuarios.doc(uid).set({
                  'nome': nomeController.text.trim(),
                  'email': emailController.text.trim(),
                  'role': role,
                  'uid': uid,
                  'criadoEm': FieldValue.serverTimestamp(),
                });

                debugPrint('✅ Colaborador $uid adicionado');
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              } catch (e) {
                debugPrint('❌ Erro ao adicionar colaborador: $e');
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao adicionar colaborador: $e')),
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
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('EquipeScreen: Iniciando build');
    return Scaffold(
      appBar: AppBar(title: Text('Equipe')),
      body: StreamBuilder(
        stream: usuarios.orderBy('nome').snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            debugPrint('EquipeScreen: Aguardando dados');
            return Center(child: CircularProgressIndicator());
          }

          final usuarios = snapshot.data.docs;

          if (usuarios.isEmpty) {
            debugPrint('EquipeScreen: Nenhum colaborador encontrado');
            return Center(child: Text('Nenhum colaborador cadastrado.'));
          }

          debugPrint(
            'EquipeScreen: ${usuarios.length} colaboradores carregados',
          );
          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final user = usuarios[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ListTile(
                  title: Text(user['nome'] ?? 'Sem nome'),
                  subtitle: Text(
                    '${user['email'] ?? 'Sem email'} - ${user['role'] ?? 'Sem cargo'}',
                  ),
                  trailing: Icon(Icons.person),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarColaborador,
        child: Icon(Icons.person_add),
      ),
    );
  }
}
