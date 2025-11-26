import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:propertask/screen/propriedades/propriedade_detalhe_screen.dart';
import 'package:propertask/screen/propriedades/propriedade_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';
import 'package:propertask/widgets/app_drawer.dart';

class PropriedadesScreen extends StatefulWidget {
  const PropriedadesScreen({super.key});

  @override
  State<PropriedadesScreen> createState() => _PropriedadesScreenState();
}

class _PropriedadesScreenState extends State<PropriedadesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _cidade = 'Todas';
  String _tipologia = 'Todas';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cargo = Provider.of<AppState>(context).usuario?.cargo ?? 'LIMPEZA';
    final podeEditar = Permissions.podeGerenciarPropriedades(cargo);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Propriedades'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      floatingActionButton: podeEditar
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PropriedadeFormScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nova propriedade'),
            )
          : null,
      drawer: const AppDrawer(currentRoute: '/propriedades'),
      body: Column(
        children: [
          // Busca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        tooltip: 'Limpar',
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: cs.surface,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          // StreamBuilder com ListView
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('propertask')
                  .doc('propriedades')
                  .collection('propriedades')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma propriedade cadastrada.'),
                  );
                }

                final allDocs = snapshot.data!.docs;
                // Opções dinâmicas
                final cidades = <String>{};
                final tipologias = <String>{};
                for (final d in allDocs) {
                  final data = d.data() as Map<String, dynamic>;
                  final c = (data['cidade'] ?? '').toString().trim();
                  final t = (data['tipologia'] ?? '').toString().trim();
                  if (c.isNotEmpty) cidades.add(c);
                  if (t.isNotEmpty) tipologias.add(t);
                }
                final cidadesList = ['Todas', ...cidades.toList()..sort()];
                final tipologiasList = [
                  'Todas',
                  ...tipologias.toList()..sort(),
                ];

                // Filtros + busca
                final filtered = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nome = (data['nome'] ?? '').toString().toLowerCase();
                  final cidade = (data['cidade'] ?? '').toString();
                  final tipologia = (data['tipologia'] ?? '').toString();
                  final matchBusca =
                      _searchQuery.isEmpty || nome.contains(_searchQuery);
                  final matchCidade = _cidade == 'Todas' || cidade == _cidade;
                  final matchTipologia =
                      _tipologia == 'Todas' || tipologia == _tipologia;
                  return matchBusca && matchCidade && matchTipologia;
                }).toList();

                return ListView(
                  padding: EdgeInsets.zero,

                  children: [
                    // Filtros
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),

                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Cidade
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: cidadesList.contains(_cidade)
                                  ? _cidade
                                  : 'Todas',
                              items: cidadesList
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _cidade = v ?? 'Todas'),
                              decoration: InputDecoration(
                                labelText: 'Cidade',
                                prefixIcon: const Icon(Icons.location_city),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tipologia
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: tipologiasList.contains(_tipologia)
                                  ? _tipologia
                                  : 'Todas',
                              items: tipologiasList
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        t,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _tipologia = v ?? 'Todas'),
                              decoration: InputDecoration(
                                labelText: 'Tipologia',
                                prefixIcon: const Icon(Icons.category),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),
                    // Lista principal
                    ...filtered.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nome = (data['nome'] ?? 'Sem nome').toString();
                      final endereco = (data['endereco'] ?? 'Sem endereço')
                          .toString();
                      final cidade = (data['cidade'] ?? '').toString();
                      final tipologia = (data['tipologia'] ?? '').toString();
                      final fotoUrl = (data['fotoUrl'] ?? '').toString();

                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PropriedadeDetalheScreen(
                                propriedadeId: doc.id,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          elevation: 2,
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(13),
                                    bottomLeft: Radius.circular(13),
                                  ),
                                  child: SizedBox(
                                    width: 120,
                                    height: double.infinity,
                                    child: fotoUrl.isNotEmpty
                                        ? Image.network(
                                            fotoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                _placeholderThumb(),
                                          )
                                        : _placeholderThumb(),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(13),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          nome,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          endereco,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 7,
                                          runSpacing: -6,
                                          children: [
                                            if (cidade.isNotEmpty)
                                              Chip(
                                                label: Text(
                                                  cidade,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            if (tipologia.isNotEmpty)
                                              Chip(
                                                label: Text(
                                                  tipologia,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      color: Colors.blueGrey.shade100,
      child: const Center(
        child: Icon(Icons.home, color: Colors.blueGrey, size: 40),
      ),
    );
  }
}
