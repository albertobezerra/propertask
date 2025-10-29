import 'package:cloud_firestore/cloud_firestore.dart';

class Tarefa {
  final String id;
  final String titulo;
  final String tipo;
  final String propriedadeId;
  final String responsavelId;
  final String status;
  final DateTime data;
  final DateTime? concluidaEm;
  final String? observacoes;

  Tarefa({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.propriedadeId,
    required this.responsavelId,
    required this.status,
    required this.data,
    this.concluidaEm,
    this.observacoes,
  });

  factory Tarefa.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tarefa(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      tipo: data['tipo'] ?? 'limpeza',
      propriedadeId: data['propriedadeId'] ?? '',
      responsavelId: data['responsavelId'] ?? '',
      status: data['status'] ?? 'pendente',
      data: (data['data'] as Timestamp).toDate(),
      concluidaEm: data['concluidaEm'] != null
          ? (data['concluidaEm'] as Timestamp).toDate()
          : null,
      observacoes: data['observacoes'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'titulo': titulo,
    'tipo': tipo,
    'propriedadeId': propriedadeId,
    'responsavelId': responsavelId,
    'status': status,
    'data': Timestamp.fromDate(data),
    if (concluidaEm != null) 'concluidaEm': Timestamp.fromDate(concluidaEm!),
    if (observacoes != null) 'observacoes': observacoes,
  };
}
