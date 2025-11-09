import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:propertask/core/utils/formatters.dart';
import 'package:propertask/widgets/app_drawer.dart';

class LavanderiaScreen extends StatelessWidget {
  const LavanderiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final amanha = DateTime.now().add(const Duration(days: 1));
    final inicio = DateTime(amanha.year, amanha.month, amanha.day);
    final fim = inicio.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: Text('Lavanderia - ${Formatters.formatDate(amanha)}'),
      ),
      drawer: const AppDrawer(currentRoute: '/lavanderia'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('propertask/tarefas/tarefas')
            .where('data', isGreaterThanOrEqualTo: inicio)
            .where('data', isLessThan: fim)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma tarefa para amanhã'));
          }

          final tarefas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tarefas.length,
            itemBuilder: (context, index) {
              final data = tarefas[index].data() as Map<String, dynamic>;
              final propId = data['propriedadeId'] as String?;

              if (propId == null) return const SizedBox();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('propertask/propriedades/propriedades')
                    .doc(propId)
                    .get(),
                builder: (context, propSnap) {
                  if (!propSnap.hasData || !propSnap.data!.exists) {
                    return const ListTile(
                      title: Text('Propriedade não encontrada'),
                    );
                  }

                  final prop = propSnap.data!.data() as Map<String, dynamic>;
                  final roupas = _calcularRoupas(prop);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.home, color: Colors.blue),
                      title: Text(prop['nome'] ?? 'Sem nome'),
                      subtitle: Text(
                        '${prop['tipologia'] ?? ''} • ${roupas.length} itens',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _mostrarRoupas(context, roupas),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<String> _calcularRoupas(Map<String, dynamic> prop) {
    final roupas = <String>[];

    // 1) Preferir mapa salvo na propriedade
    final roupaMapDyn = prop['roupa'];
    if (roupaMapDyn is Map) {
      final roupaMap = Map<String, dynamic>.from(roupaMapDyn);
      roupaMap.forEach((k, v) {
        final key = k.toString();
        final qtd = (v is int)
            ? v
            : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
        if (qtd > 0) {
          for (var i = 0; i < qtd; i++) {
            roupas.add(key);
          }
        }
      });
      if (roupas.isNotEmpty) return roupas;
    }

    // 2) Fallback por tipologia (legado)
    final tipo = prop['tipologia']?.toString() ?? 'T1';
    final config = {
      'T0': {
        'lençol_casal': 1,
        'capa_casal': 1,
        'fronha': 2,
        'toalha_banho': 1,
        'toalha_rosto': 1,
        'tapete': 1,
        'pano_limpeza': 1,
      },
      'T1': {
        'lençol_casal': 1,
        'capa_casal': 1,
        'fronha': 2,
        'toalha_banho': 2,
        'toalha_rosto': 2,
        'tapete': 1,
        'pano_limpeza': 1,
      },
      'T2': {
        'lençol_casal': 2,
        'capa_casal': 2,
        'fronha': 4,
        'toalha_banho': 4,
        'toalha_rosto': 4,
        'tapete': 2,
        'pano_limpeza': 1,
      },
    };

    final mapa = config[tipo] ?? config['T1']!;
    mapa.forEach((item, qtd) {
      for (int i = 0; i < qtd; i++) {
        roupas.add(item);
      }
    });
    return roupas;
  }

  void _mostrarRoupas(BuildContext context, List<String> roupas) {
    final contagem = <String, int>{};
    for (var r in roupas) {
      contagem[r] = (contagem[r] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Roupas para Lavar'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: contagem.entries.map((e) {
              final nome = e.key
                  .replaceAll('_', ' ')
                  .replaceAll('lencol', 'lençol')
                  .replaceAll('casal', 'de casal')
                  .replaceAll('solteiro', 'de solteiro')
                  .replaceAll('banho', 'de banho')
                  .replaceAll('rosto', 'de rosto')
                  .replaceAll('pano limpeza', 'pano de limpeza');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${e.value}x $nome'),
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
}
