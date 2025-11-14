import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String cargo;
  final String? telefone;
  final String? fotoUrl; // <- ADICIONE ESSE CAMPO!
  final bool ativo;
  final Timestamp criadoEm;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.cargo,
    this.telefone,
    this.fotoUrl,
    required this.ativo,
    required this.criadoEm,
  });

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Usuario(
      id: doc.id,
      nome: data['nome'] ?? 'Usuário',
      email: data['email'] ?? '',
      cargo: data['cargo'] ?? 'LIMPEZA',
      telefone: data['telefone'],
      fotoUrl: data['fotoUrl'],
      criadoEm: data['criadoEm'] ?? Timestamp.now(),
      ativo: data['ativo'] == true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'nome': nome,
    'email': email,
    'cargo': cargo,
    'telefone': telefone,
    'fotoUrl': fotoUrl, // <- ADICIONE ESSE CAMPO!
    'criadoEm': criadoEm,
    'ativo': ativo,
  };
}
