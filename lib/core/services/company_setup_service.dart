import 'package:cloud_firestore/cloud_firestore.dart';

class CompanySetupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createEmpresa({
    required String empresaId,
    required String nomeEmpresa,
    required String coordenadorUid,
    required String coordenadorEmail,
    required String coordenadorNome,
  }) async {
    final empresaRef = _firestore.collection('empresas').doc(empresaId);
    if ((await empresaRef.get()).exists) return;

    await empresaRef.set({
      'nome': nomeEmpresa,
      'coordenadorUid': coordenadorUid,
      'criadoEm': FieldValue.serverTimestamp(),
      'ativa': true,
    });

    await empresaRef.collection('usuarios').doc(coordenadorUid).set({
      'id': coordenadorUid,
      'empresaId': empresaId,
      'nome': coordenadorNome,
      'email': coordenadorEmail,
      'cargo': 'COORDENADOR',
      'criadoEm': FieldValue.serverTimestamp(),
      'ativo': true,
    });

    await empresaRef.collection('propriedades').add({
      'nome': 'Propriedade Exemplo',
      'localizacao': 'A definir',
      'tipologia': 'T1',
      'acesso': 'chave',
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }
}
