// lib/screen/lavanderia/lavanderia_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:propertask/core/utils/formatters.dart';
import 'package:propertask/widgets/app_drawer.dart';

// Modelo para a lista
class LavItem {
  final String propriedadeId;
  final String propriedadeNome;
  final String tipologia;
  final String fornecedor;
  final Map<String, int> contagem;

  LavItem({
    required this.propriedadeId,
    required this.propriedadeNome,
    required this.tipologia,
    required this.fornecedor,
    required this.contagem,
  });
}

class LavanderiaScreen extends StatefulWidget {
  const LavanderiaScreen({super.key});

  @override
  State<LavanderiaScreen> createState() => _LavanderiaScreenState();
}

class _LavanderiaScreenState extends State<LavanderiaScreen> {
  // Data de lavagem (D-1): consulta tarefas no dia seguinte
  DateTime _lavagem = DateTime.now();

  // Visualização
  bool _groupByFornecedor = true;

  @override
  Widget build(BuildContext context) {
    // Tarefas do dia seguinte à data de lavagem
    final diaTarefa = _lavagem.add(const Duration(days: 1));
    final inicio = DateTime(diaTarefa.year, diaTarefa.month, diaTarefa.day);
    final fim = inicio.add(const Duration(days: 1));

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/lavanderia'),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            title: const Text('Lavanderia'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildHeaderControls(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('propertask/tarefas/tarefas')
                  .where('tipo', isEqualTo: 'LIMPEZA')
                  .where('data', isGreaterThanOrEqualTo: inicio)
                  .where('data', isLessThan: fim)
                  .snapshots(),
              builder: (context, snapTarefas) {
                if (snapTarefas.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapTarefas.hasData || snapTarefas.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: _emptyCard(
                      context,
                      'Nenhuma tarefa de LIMPEZA para ${Formatters.formatDate(diaTarefa)}',
                    ),
                  );
                }

                final tarefas = snapTarefas.data!.docs;
                final propIds = <String>{};
                for (final t in tarefas) {
                  final data = t.data() as Map<String, dynamic>;
                  final id = data['propriedadeId'] as String?;
                  if (id != null && id.isNotEmpty) propIds.add(id);
                }
                if (propIds.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: _emptyCard(
                      context,
                      'Tarefas sem propriedade vinculada',
                    ),
                  );
                }

                // Carregar propriedades relacionadas
                return FutureBuilder<List<DocumentSnapshot>>(
                  future: Future.wait(
                    propIds.map(
                      (id) => FirebaseFirestore.instance
                          .collection('propertask/propriedades/propriedades')
                          .doc(id)
                          .get(),
                    ),
                  ),
                  builder: (context, snapProps) {
                    if (snapProps.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final propsDocs = (snapProps.data ?? [])
                        .where((d) => d.exists)
                        .toList();
                    if (propsDocs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: _emptyCard(
                          context,
                          'Propriedades não encontradas',
                        ),
                      );
                    }

                    // Mapear propriedadeId -> dados
                    final propsMap = <String, Map<String, dynamic>>{};
                    for (final d in propsDocs) {
                      propsMap[d.id] = (d.data() as Map<String, dynamic>);
                    }

                    // Montar itens: cada tarefa aponta para uma propriedade e suas roupas
                    final itens = <LavItem>[];
                    for (final t in tarefas) {
                      final td = t.data() as Map<String, dynamic>;
                      final pid = td['propriedadeId'] as String?;
                      if (pid == null) continue;
                      final prop = propsMap[pid];
                      if (prop == null) continue;

                      final nome = (prop['nome'] ?? 'Sem nome').toString();
                      final tipologia = (prop['tipologia'] ?? '').toString();
                      final fornecedor = (prop['fornecedorRoupa'] ?? '—')
                          .toString();

                      final count = _contarRoupas(prop);
                      itens.add(
                        LavItem(
                          propriedadeId: pid,
                          propriedadeNome: nome,
                          tipologia: tipologia,
                          fornecedor: fornecedor,
                          contagem: count,
                        ),
                      );
                    }

                    // UI: agrupado por fornecedor ou lista simples
                    if (_groupByFornecedor) {
                      return _buildGroupedByFornecedor(context, itens);
                    } else {
                      return _buildFlatList(context, itens);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Cabeçalho ----------

  Widget _buildHeaderControls(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final diaTarefa = _lavagem.add(const Duration(days: 1));
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data de lavagem (D-1)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: -8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text(Formatters.formatDate(_lavagem)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _lavagem,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(
                        () => _lavagem = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                        ),
                      );
                    }
                  },
                ),
                Chip(
                  label: Text(
                    'Tarefas em: ${Formatters.formatDate(diaTarefa)}',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                ChoiceChip(
                  label: const Text('Agrupar por fornecedor'),
                  selected: _groupByFornecedor,
                  onSelected: (v) => setState(() => _groupByFornecedor = v),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Lista plana ----------

  Widget _buildFlatList(BuildContext context, List<LavItem> itens) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: itens.map((item) {
          final total = item.contagem.values.fold<int>(0, (a, b) => a + b);
          return Card(
            color: cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.home, color: Colors.blue),
              title: Text(item.propriedadeNome),
              subtitle: Wrap(
                spacing: 6,
                runSpacing: -6,
                children: [
                  if (item.tipologia.isNotEmpty)
                    Chip(
                      label: Text(item.tipologia),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: cs.primaryContainer,
                      labelStyle: TextStyle(color: cs.onPrimaryContainer),
                    ),
                  Chip(
                    label: Text('$total itens'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _mostrarContagem(
                context,
                '${item.propriedadeNome} — Itens',
                item.contagem,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- Agrupado por fornecedor ----------

  Widget _buildGroupedByFornecedor(BuildContext context, List<LavItem> itens) {
    final cs = Theme.of(context).colorScheme;

    // Agrupar
    final grupos = <String, List<LavItem>>{};
    for (final it in itens) {
      final key = it.fornecedor.isEmpty ? '—' : it.fornecedor;
      (grupos[key] ??= []).add(it);
    }

    // Totais por grupo
    Map<String, int> somaMaps(List<LavItem> list) {
      final acc = <String, int>{};
      for (final it in list) {
        it.contagem.forEach((k, v) => acc[k] = (acc[k] ?? 0) + v);
      }
      return acc;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: grupos.entries.map((entry) {
          final fornecedor = entry.key;
          final list = entry.value;
          final totalGroup = list.fold<int>(
            0,
            (a, it) => a + it.contagem.values.fold<int>(0, (x, y) => x + y),
          );
          final totais = somaMaps(list);

          return Card(
            color: cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do grupo
                  Row(
                    children: [
                      const Icon(Icons.local_laundry_service),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fornecedor,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('Total: $totalGroup itens'),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => _mostrarContagem(
                          context,
                          'Totais — $fornecedor',
                          totais,
                        ),
                        icon: const Icon(Icons.summarize),
                        label: const Text('Ver totais'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Totais como chips (amostra)
                  Wrap(
                    spacing: 8,
                    runSpacing: -8,
                    children: _chipsFromContagem(context, totais, maxItems: 8),
                  ),
                  const SizedBox(height: 8),
                  // Itens do grupo (propriedades)
                  ...list.map((item) {
                    final total = item.contagem.values.fold<int>(
                      0,
                      (a, b) => a + b,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.home, color: Colors.blue),
                      title: Text(item.propriedadeNome),
                      subtitle: Text(
                        item.tipologia.isEmpty ? '' : item.tipologia,
                      ),
                      trailing: Chip(
                        label: Text('$total'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: cs.primaryContainer,
                        labelStyle: TextStyle(color: cs.onPrimaryContainer),
                      ),
                      onTap: () => _mostrarContagem(
                        context,
                        '${item.propriedadeNome} — Itens',
                        item.contagem,
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- Dialog genérico para contagens ----------

  void _mostrarContagem(
    BuildContext context,
    String titulo,
    Map<String, int> contagem,
  ) {
    final ordenado = contagem.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: ordenado.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('• ${e.value}x ${_labelItem(e.key, e.value)}'),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ---------- Utilidades de UI ----------

  Widget _emptyCard(BuildContext context, String msg) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
  }

  List<Widget> _chipsFromContagem(
    BuildContext context,
    Map<String, int> cont, {
    int maxItems = 9999,
  }) {
    final cs = Theme.of(context).colorScheme;
    final list = cont.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sliced = list.take(maxItems);
    return sliced.map((e) {
      final label = '${e.value}x ${_titleCase(_labelItem(e.key, e.value))}';
      return Chip(
        label: Text(label),
        visualDensity: VisualDensity.compact,
        backgroundColor: cs.secondaryContainer,
        labelStyle: TextStyle(color: cs.onSecondaryContainer),
      );
    }).toList();
  }

  // ---------- Cálculo de roupas ----------

  Map<String, int> _contarRoupas(Map<String, dynamic> prop) {
    final out = <String, int>{};

    // 1) Preferir mapa salvo na propriedade
    final roupaMapDyn = prop['roupa'];
    if (roupaMapDyn is Map) {
      final m = Map<String, dynamic>.from(roupaMapDyn);
      m.forEach((k, v) {
        final key = k.toString();
        final qtd = (v is int)
            ? v
            : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
        if (qtd > 0) out[key] = (out[key] ?? 0) + qtd;
      });
    }

    if (out.isNotEmpty) return out;

    // 2) Fallback por tipologia (legado)
    final tipo = prop['tipologia']?.toString() ?? 'T1';
    final banhos = (prop['banhos'] is int) ? prop['banhos'] as int : 1;

    final base = {
      'T0': {
        'lençol_casal': 1,
        'capa_casal': 1,
        'fronha': 2,
        'toalha_banho': 1,
        'toalha_rosto': 1,
        'tapete': banhos > 0 ? banhos : 1,
        'pano_limpeza': 1,
      },
      'T1': {
        'lençol_casal': 1,
        'capa_casal': 1,
        'fronha': 2,
        'toalha_banho': 2,
        'toalha_rosto': 2,
        'tapete': banhos > 0 ? banhos : 1,
        'pano_limpeza': 1,
      },
      'T2': {
        'lençol_casal': 2,
        'capa_casal': 2,
        'fronha': 4,
        'toalha_banho': 4,
        'toalha_rosto': 4,
        'tapete': banhos > 0 ? banhos : 2,
        'pano_limpeza': 1,
      },
      // Ajuste para T3+ se necessário
    };

    final mapa = base[tipo] ?? base['T1']!;
    mapa.forEach((k, v) => out[k] = (out[k] ?? 0) + v);
    return out;
  }

  // ---------- Formatação ----------

  String _labelItem(String key, int qtd) {
    String nome = key
        .replaceAll('_', ' ')
        .replaceAll('lencol', 'lençol')
        .replaceAll('casal', 'de casal')
        .replaceAll('solteiro', 'de solteiro')
        .replaceAll('banho', 'de banho')
        .replaceAll('rosto', 'de rosto')
        .replaceAll('pano limpeza', 'pano de cozinha');
    if (qtd != 1) {
      nome = nome
          .replaceAll('fronha', 'fronhas')
          .replaceAll('lençol', 'lençóis')
          .replaceAll('capa', 'capas')
          .replaceAll('toalha', 'toalhas')
          .replaceAll('tapete', 'tapetes')
          .replaceAll('pano de cozinha', 'panos de cozinha');
    }
    return nome;
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
