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
    final empresaId = appState.empresaId!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipe'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ),
      ),
      floatingActionButton: podeEditar
          ? FloatingActionButton.extended(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final route = MaterialPageRoute<bool>(
                  builder: (_) => UsuarioFormScreen(
                    adminEmail: emailAtual,
                    adminPassword: senhaAtual,
                  ),
                );
                final result = await navigator.push(route);
                if (!mounted) return;
                if (result == true) setState(() {});
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo funcionário'),
            )
          : null,
      drawer: const AppDrawer(currentRoute: '/equipe'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Buscar funcionário...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('empresas')
                  .doc(empresaId)
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
                        horizontal: 14,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ativo ? Colors.green : Colors.red,
                          backgroundImage:
                              data['fotoUrl'] != null &&
                                  (data['fotoUrl'] as String).isNotEmpty
                              ? NetworkImage(data['fotoUrl'])
                              : null,
                          child:
                              (data['fotoUrl'] == null ||
                                  (data['fotoUrl'] as String).isEmpty)
                              ? Text(
                                  nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(
                          nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Chip(
                                label: Text(
                                  formatCargo(cargo),
                                  style: TextStyle(
                                    color: getCargoColor(cargo),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        trailing: podeEditar
                            ? PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    final navigator = Navigator.of(context);
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
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    await toggleAtivo(doc, messenger);
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

  String formatCargo(String cargo) {
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

  Color getCargoColor(String cargo) {
    const map = {
      'DEV': Colors.purple,
      'CEO': Colors.red,
      'COORDENADOR': Colors.orange,
      'SUPERVISOR': Colors.blue,
    };
    return map[cargo] ?? Colors.grey;
  }

  Future<void> toggleAtivo(
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
