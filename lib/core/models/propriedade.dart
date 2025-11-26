import 'package:cloud_firestore/cloud_firestore.dart';

class Propriedade {
  final String id;
  final String empresaId; // NOVO
  final String nome;
  final String endereco;
  final String acesso;
  final String? codigoAcesso;
  final String? lockboxLocal;
  final List<String> fotos;
  final String tipologia;
  final DateTime criadoEm;

  Propriedade({
    required this.id,
    required this.empresaId, // NOVO
    required this.nome,
    required this.endereco,
    required this.acesso,
    this.codigoAcesso,
    this.lockboxLocal,
    required this.fotos,
    required this.tipologia,
    required this.criadoEm,
  });

  factory Propriedade.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Propriedade(
      id: doc.id,
      empresaId: data['empresaId'] ?? '', // NOVO
      nome: data['nome'] ?? '',
      endereco: data['endereco'] ?? '',
      acesso: data['acesso'] ?? 'chave',
      codigoAcesso: data['codigoAcesso'],
      lockboxLocal: data['lockboxLocal'],
      fotos: List<String>.from(data['fotos'] ?? []),
      tipologia: data['tipologia'] ?? 'T1',
      criadoEm: (data['criadoEm'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'empresaId': empresaId, // NOVO
    'nome': nome,
    'endereco': endereco,
    'acesso': acesso,
    'codigoAcesso': codigoAcesso,
    'lockboxLocal': lockboxLocal,
    'fotos': fotos,
    'tipologia': tipologia,
    'criadoEm': Timestamp.fromDate(criadoEm),
  };
}
