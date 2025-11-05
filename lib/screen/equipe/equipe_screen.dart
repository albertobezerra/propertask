import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:propertask/screen/equipe/usuario_form_screen.dart';
import 'package:propertask/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';

class EquipeScreen extends StatefulWidget {
  const EquipeScreen({super.key});

  @override
  State<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends State<EquipeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cargo = Provider.of<AppState>(context).usuario?.cargo ?? 'LIMPEZA';
    final podeEditar = Permissions.podeGerenciarUsuarios(cargo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipe'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (podeEditar)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsuarioFormScreen()),
                );
                if (!mounted) return;
                if (result == true) setState(() {});
              },
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/equipe'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Buscar funcionário...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('propertask')
                  .doc('usuarios')
                  .collection('usuarios')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum funcionário cadastrado.'),
                  );
                }

                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nome = (data['nome'] ?? '').toString().toLowerCase();
                  return nome.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final nome = data['nome'] ?? 'Sem nome';
                    final email = data['email'] ?? 'Sem email';
                    final cargo = data['cargo'] ?? 'LIMPEZA';
                    final ativo = data['ativo'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ativo ? Colors.green : Colors.red,
                          child: Text(
                            nome.isNotEmpty ? nome[0].toUpperCase() : '?',
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
                            Text(email),
                            Text(
                              _formatCargo(cargo),
                              style: TextStyle(color: _getCargoColor(cargo)),
                            ),
                          ],
                        ),
                        trailing: podeEditar
                            ? PopupMenuButton(
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UsuarioFormScreen(usuario: doc),
                                      ),
                                    ).then((_) {
                                      if (!mounted) return;
                                      setState(() {});
                                    });
                                  } else if (v == 'toggle') {
                                    _toggleAtivo(context, doc);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Text(ativo ? 'Desativar' : 'Ativar'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatCargo(String cargo) {
    const map = {
      'DEV': 'Desenvolvedor',
      'CEO': 'CEO',
      'COORDENADOR': 'Coordenador',
      'SUPERVISOR': 'Supervisor',
      'LIMPEZA': 'Limpeza',
      'LAVANDERIA': 'Lavanderia',
      'MOTORISTA': 'Motorista',
    };
    return map[cargo] ?? cargo;
  }

  Color _getCargoColor(String cargo) {
    const map = {
      'DEV': Colors.purple,
      'CEO': Colors.red,
      'COORDENADOR': Colors.orange,
      'SUPERVISOR': Colors.blue,
    };
    return map[cargo] ?? Colors.grey;
  }

  void _toggleAtivo(BuildContext context, DocumentSnapshot doc) async {
    final ctx = context; // ← SALVA ANTES DO AWAIT
    final data = doc.data() as Map<String, dynamic>;
    final novoAtivo = !(data['ativo'] == true);

    try {
      await doc.reference.update({'ativo': novoAtivo});
      if (!ctx.mounted) return; // ← VERIFICA O MESMO CONTEXT
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(novoAtivo ? 'Ativado' : 'Desativado')),
      );
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
