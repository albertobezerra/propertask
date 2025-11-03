import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PropriedadeDetalheScreen extends StatelessWidget {
  final String propriedadeId;

  const PropriedadeDetalheScreen({super.key, required this.propriedadeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Propriedade')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('propertask')
            .doc('propriedades')
            .collection('propriedades')
            .doc(propriedadeId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _infoRow('Nome', data['nome']),
              _infoRow('Endereço', data['endereco']),
              _infoRow('Acesso', data['acesso']?.toString().toUpperCase()),
              if (data['codigoAcesso'] != null)
                _infoRow('Código', data['codigoAcesso']),
              if (data['lockboxLocal'] != null)
                _infoRow('Lockbox', data['lockboxLocal']),
              _infoRow('Tipologia', data['tipologia']),
              const SizedBox(height: 20),
              const Text(
                'Fotos: (em breve)',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? '—')),
        ],
      ),
    );
  }
}
