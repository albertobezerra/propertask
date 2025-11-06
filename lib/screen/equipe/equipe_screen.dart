// lib/screen/equipe/equipe_screen.dart
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
    final appState = Provider.of<AppState>(context);
    final cargo = appState.usuario?.cargo ?? 'LIMPEZA';
    final podeEditar = Permissions.podeGerenciarUsuarios(cargo);
    final emailAtual = appState.usuario?.email ?? '';
    final senhaAtual = appState.senhaUsuario ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipe'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
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
                final navigator = Navigator.of(
                  context,
                ); // capture antes do await
                final route = MaterialPageRoute<bool>(
                  builder: (_) => UsuarioFormScreen(
                    adminEmail: emailAtual,
                    adminPassword: senhaAtual,
                  ),
                );
                final result = await navigator.push(route);
                if (!mounted) return;
                if (result == true) setState(() {}); // seguro após mounted
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
                  final data = doc.data()! as Map<String, dynamic>;
                  final nome = (data['nome'] ?? '').toString().toLowerCase();
                  return nome.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data()! as Map<String, dynamic>;
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
                            ? PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    final navigator = Navigator.of(
                                      context,
                                    ); // capture antes do await
                                    final res = await navigator.push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => UsuarioFormScreen(
                                          usuario: doc,
                                          adminEmail: emailAtual,
                                          adminPassword: senhaAtual,
                                        ),
                                      ),
                                    );
                                    if (!mounted) return;
                                    if (res == true) setState(() {});
                                  } else if (v == 'toggle') {
                                    // Captura o messenger e não usa Of(context) após await
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    await _toggleAtivo(doc, messenger);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Text('Desativar/Ativar'),
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
      'RH': 'RH',
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

  // NÃO usa BuildContext após await; recebe o messenger já resolvido
  Future<void> _toggleAtivo(
    DocumentSnapshot doc,
    ScaffoldMessengerState messenger,
  ) async {
    final data = doc.data()! as Map<String, dynamic>;
    final novoAtivo = !(data['ativo'] == true);
    try {
      await doc.reference.update({'ativo': novoAtivo});
      messenger.showSnackBar(
        SnackBar(content: Text(novoAtivo ? 'Ativado' : 'Desativado')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
