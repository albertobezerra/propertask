import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LavanderiaScreen extends StatelessWidget {
  const LavanderiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final inicio = DateTime(
      agora.year,
      agora.month,
      agora.day + 1,
      0,
      0,
      0,
    ); // Amanhã
    final fim = inicio.add(const Duration(days: 1));

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lavanderia'),
        backgroundColor: Colors.deepPurple, // ou padrão dash
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('propertask')
            .doc('tarefas')
            .collection('tarefas')
            .where('tipo', isEqualTo: 'limpeza')
            .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
            .where('data', isLessThan: Timestamp.fromDate(fim))
            .snapshots(),
        builder: (context, tarefasSnap) {
          if (tarefasSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!tarefasSnap.hasData || tarefasSnap.data!.docs.isEmpty) {
            return const Center(child: Text('Sem tarefas para amanhã.'));
          }
          final tarefas = tarefasSnap.data!.docs;
          final propIds = tarefas
              .map((t) => t['propriedadeId'] as String)
              .toSet()
              .toList();

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('propertask')
                .doc('propriedades')
                .collection('propriedades')
                .where(FieldPath.documentId, whereIn: propIds)
                .get(),
            builder: (context, propsSnap) {
              if (!propsSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              // propriedades por id
              final props = {
                for (var doc in propsSnap.data!.docs)
                  doc.id: doc.data() as Map<String, dynamic>,
              };

              // agrupamento por fornecedor
              Map<String, List<Map<String, dynamic>>> porFornecedor = {};
              for (var tarefa in tarefas) {
                final propId = tarefa['propriedadeId'] as String;
                final prop = props[propId];
                if (prop == null) continue;
                final fornecedor = prop['fornecedorRoupa'] ?? 'N/A';
                porFornecedor.putIfAbsent(fornecedor, () => []);
                porFornecedor[fornecedor]!.add(prop);
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
                children: porFornecedor.entries.map((grupo) {
                  final fornecedor = grupo.key;
                  final propriedades = grupo.value;

                  // Soma quantidades total de roupa deste fornecedor
                  final totalRoupas = <String, int>{};
                  for (var prop in propriedades) {
                    final roupa = (prop['roupa'] ?? {}) as Map<String, dynamic>;
                    roupa.forEach((tipo, qtd) {
                      totalRoupas[tipo] =
                          (totalRoupas[tipo] ?? 0) + (qtd as int? ?? 0);
                    });
                  }

                  return Card(
                    color: cs.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título agrupado do fornecedor com badge
                          Row(
                            children: [
                              Icon(
                                Icons.local_laundry_service,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                fornecedor,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary,
                                    ),
                              ),
                              Spacer(),
                              Chip(
                                label: Text(
                                  '${propriedades.length} propriedades',
                                ),
                                backgroundColor: cs.primaryContainer,
                                labelStyle: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Chips para peças totais
                          Wrap(
                            spacing: 8,
                            runSpacing: -8,
                            children: totalRoupas.entries
                                .where((e) => (e.value) > 0)
                                .map(
                                  (e) => Chip(
                                    avatar: Icon(
                                      Icons.checkroom,
                                      size: 15,
                                      color: cs.secondary,
                                    ),
                                    label: Text(
                                      '${e.value}x ${_formatNomeItem(e.key, e.value)}',
                                    ),
                                    backgroundColor: cs.secondaryContainer,
                                    labelStyle: TextStyle(
                                      color: cs.onSecondaryContainer,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 10),

                          // Lista das propriedades de cada fornecedor
                          ...propriedades.map((prop) {
                            final nome = prop['nome'] ?? '';
                            final tipologia = prop['tipologia'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.apartment,
                                    size: 15,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$nome • $tipologia',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  String _formatNomeItem(String key, int qtd) {
    String nome = key
        .replaceAll('_', ' ')
        .replaceAll('lencol', 'lençol')
        .replaceAll('casal', 'de casal')
        .replaceAll('solteiro', 'de solteiro')
        .replaceAll('banho', 'de banho')
        .replaceAll('rosto', 'de rosto')
        .replaceAll('pano limpeza', 'pano de limpeza');
    if (qtd != 1) {
      nome = nome
          .replaceAll('fronha', 'fronhas')
          .replaceAll('lençol', 'lençóis')
          .replaceAll('capa', 'capas')
          .replaceAll('toalha', 'toalhas')
          .replaceAll('tapete', 'tapetes')
          .replaceAll('pano de limpeza', 'panos de limpeza');
    }
    return nome[0].toUpperCase() + nome.substring(1);
  }
}
