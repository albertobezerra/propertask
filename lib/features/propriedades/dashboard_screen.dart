import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:propertask/features/equipe/equipe_screen.dart';
import 'propriedade_detalhe_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  CollectionReference get propriedades => FirebaseFirestore.instance
      .collection('propertask')
      .doc('propriedades')
      .collection('propriedades');

  void _adicionarPropriedade(BuildContext context) {
    TextEditingController nomeController = TextEditingController();
    TextEditingController enderecoController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Nova Propriedade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(hintText: 'Nome da propriedade'),
            ),
            TextField(
              controller: enderecoController,
              decoration: InputDecoration(hintText: 'Localização'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (nomeController.text.isNotEmpty) {
                try {
                  final propDoc = await propriedades.add({
                    'nome': nomeController.text,
                    'localizacao': enderecoController.text,
                    'criadoEm': Timestamp.now(),
                  });
                  debugPrint(
                    '✅ Propriedade adicionada: ${nomeController.text} (ID: ${propDoc.id})',
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  debugPrint('❌ Erro ao adicionar propriedade: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao adicionar propriedade: $e'),
                    ),
                  );
                }
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
    debugPrint('Dashboard: Iniciando build');
    return Scaffold(
      appBar: AppBar(
        title: Text('Propertask - Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EquipeScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: propriedades.orderBy('criadoEm').snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('StreamBuilder: Aguardando dados');
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Erro no StreamBuilder: ${snapshot.error}');
            return Center(
              child: Text('Erro ao carregar propriedades: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
            debugPrint('StreamBuilder: Nenhuma propriedade encontrada');
            return Center(
              child: Text(
                'Nenhuma propriedade encontrada. Clique em "+" para adicionar.',
              ),
            );
          }

          final propriedades = snapshot.data.docs;
          debugPrint(
            'StreamBuilder: ${propriedades.length} propriedades carregadas',
          );

          return ListView.builder(
            itemCount: propriedades.length,
            itemBuilder: (context, index) {
              var propriedade = propriedades[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ListTile(
                  title: Text(propriedade['nome'] ?? 'Sem nome'),
                  subtitle: Text(
                    propriedade['localizacao'] ?? 'Sem localização',
                  ),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropriedadeDetalheScreen(
                          propriedadeId: propriedade.id,
                          propriedadeNome: propriedade['nome'] ?? 'Sem nome',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _adicionarPropriedade(context),
        child: Icon(Icons.add),
      ),
    );
  }
}
