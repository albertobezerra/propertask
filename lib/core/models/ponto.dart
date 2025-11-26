import 'package:cloud_firestore/cloud_firestore.dart';

class Ponto {
  final String id;
  final String empresaId; // NOVO, opcional (se fizer sentido)
  final String usuarioId;
  final String tipo;
  final DateTime horarioReal;
  final DateTime horarioArredondado;
  final GeoPoint localizacao;
  final String? observacao;
  final String? alteradoPor;
  final DateTime? alteradoEm;

  Ponto({
    required this.id,
    required this.empresaId, // NOVO, opcional
    required this.usuarioId,
    required this.tipo,
    required this.horarioReal,
    required this.horarioArredondado,
    required this.localizacao,
    this.observacao,
    this.alteradoPor,
    this.alteradoEm,
  });

  factory Ponto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ponto(
      id: doc.id,
      empresaId: data['empresaId'] ?? '', // NOVO
      usuarioId: data['usuarioId'],
      tipo: data['tipo'],
      horarioReal: (data['horarioReal'] as Timestamp).toDate(),
      horarioArredondado: (data['horarioArredondado'] as Timestamp).toDate(),
      localizacao: data['localizacao'],
      observacao: data['observacao'],
      alteradoPor: data['alteradoPor'],
      alteradoEm: data['alteradoEm'] != null
          ? (data['alteradoEm'] as Timestamp).toDate()
          : null,
    );
  }
}
