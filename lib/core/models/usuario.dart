// lib/core/models/usuario.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String cargo;
  final String? telefone;
  final Timestamp criadoEm;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.cargo,
    this.telefone,
    required this.criadoEm,
  });

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Documento vazio: ${doc.id}');
    }

    final rawCargo = data['cargo']?.toString() ?? 'LIMPEZA';
    final cargoNormalizado = rawCargo.toUpperCase();

    return Usuario(
      id: doc.id,
      nome: data['nome'] ?? 'Usuário',
      email: data['email'] ?? '',
      cargo: cargoNormalizado,
      telefone: data['telefone'],
      criadoEm: data['criadoEm'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'nome': nome,
    'email': email,
    'cargo': cargo,
    'telefone': telefone,
    'criadoEm': criadoEm,
  };
}
