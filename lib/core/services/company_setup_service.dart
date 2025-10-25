import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

    final doc = await empresaRef.get();
    if (doc.exists) {
      debugPrint('⚠️ Empresa "$empresaId" já existe. Pulando criação.');
      return;
    }

    debugPrint('🏗️ Criando empresa "$nomeEmpresa"...');

    await empresaRef.set({
      'nome': nomeEmpresa,
      'coordenadorUid': coordenadorUid,
      'criadoEm': FieldValue.serverTimestamp(),
      'ativa': true,
    });

    await empresaRef.collection('usuarios').doc(coordenadorUid).set({
      'uid': coordenadorUid,
      'nome': coordenadorNome,
      'email': coordenadorEmail,
      'cargo': 'Coordenador',
      'criadoEm': FieldValue.serverTimestamp(),
    });

    await empresaRef.collection('propriedades').add({
      'nome': 'Propriedade Exemplo',
      'localizacao': 'A definir',
      'criadoEm': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Empresa "$nomeEmpresa" criada com sucesso!');
  }
}
