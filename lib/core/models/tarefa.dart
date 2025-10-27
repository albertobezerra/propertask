import 'package:cloud_firestore/cloud_firestore.dart';

class Tarefa {
  final String id;
  final String titulo;
  final String propriedadeId;
  final String status;
  final String responsavelId;
  final DateTime criadoEm;

  Tarefa({
    required this.id,
    required this.titulo,
    required this.propriedadeId,
    required this.status,
    required this.responsavelId,
    required this.criadoEm,
  });

  factory Tarefa.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tarefa(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      propriedadeId: data['propriedadeId'] ?? '',
      status: data['status'] ?? 'pendente',
      responsavelId: data['responsavelId'] ?? '',
      criadoEm: (data['criadoEm'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'propriedadeId': propriedadeId,
      'status': status,
      'responsavelId': responsavelId,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }
}
