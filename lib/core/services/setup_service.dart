import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SetupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeEmpresaStructure(String empresaId) async {
    final empresaRef = _firestore.collection('empresas').doc(empresaId);

    final doc = await empresaRef.get();
    if (doc.exists) {
      debugPrint('✅ Estrutura da empresa $empresaId já existe.');
      return;
    }

    debugPrint('🏗️ Criando estrutura base para a empresa $empresaId...');

    await empresaRef.set({
      'nome': 'Kilometros Ecléticos',
      'criadoEm': FieldValue.serverTimestamp(),
      'ativa': true,
    });

    await empresaRef.collection('propriedades').add({
      'nome': 'Propriedade Exemplo',
      'localizacao': 'A definir',
      'criadoEm': FieldValue.serverTimestamp(),
    });

    await empresaRef.collection('usuarios').add({
      'nome': 'Coordenador Exemplo',
      'email': 'coordenador@empresa.com',
      'cargo': 'Administrador',
      'criadoEm': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Estrutura inicial criada para empresa $empresaId!');
  }
}
