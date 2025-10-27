import 'package:cloud_firestore/cloud_firestore.dart';

class Propriedade {
  final String id;
  final String nome;
  final String localizacao;
  final DateTime criadoEm;
  final String? imageUrl;

  Propriedade({
    required this.id,
    required this.nome,
    required this.localizacao,
    required this.criadoEm,
    this.imageUrl,
  });

  factory Propriedade.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Propriedade(
      id: doc.id,
      nome: data['nome'] ?? '',
      localizacao: data['localizacao'] ?? '',
      criadoEm: (data['criadoEm'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'localizacao': localizacao,
      'criadoEm': Timestamp.fromDate(criadoEm),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
