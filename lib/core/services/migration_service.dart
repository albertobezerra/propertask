import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MigrationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> migrarEmpresaUnicaParaMultiEmpresa({
    required String empresaId,
  }) async {
    debugPrint('--- INICIANDO MIGRAÇÃO ---');

    // Usuários
    debugPrint('Migrando usuários...');
    final usuarios = await _db
        .collection('propertask')
        .doc('usuarios')
        .collection('usuarios')
        .get();
    for (final doc in usuarios.docs) {
      final data = doc.data();
      debugPrint('Usuário mig: ${doc.id}');
      await _db
          .collection('empresas')
          .doc(empresaId)
          .collection('usuarios')
          .doc(doc.id)
          .set({...data, 'empresaId': empresaId});
    }

    // Tarefas
    debugPrint('Migrando tarefas...');
    final tarefas = await _db
        .collection('propertask')
        .doc('tarefas')
        .collection('tarefas')
        .get();
    for (final doc in tarefas.docs) {
      final data = doc.data();
      debugPrint('Tarefa mig: ${doc.id}');
      await _db
          .collection('empresas')
          .doc(empresaId)
          .collection('tarefas')
          .doc(doc.id)
          .set({...data, 'empresaId': empresaId});
    }

    // Propriedades
    debugPrint('Migrando propriedades...');
    final props = await _db
        .collection('propertask')
        .doc('propriedades')
        .collection('propriedades')
        .get();
    for (final doc in props.docs) {
      final data = doc.data();
      debugPrint('Propriedade mig: ${doc.id}');
      await _db
          .collection('empresas')
          .doc(empresaId)
          .collection('propriedades')
          .doc(doc.id)
          .set({...data, 'empresaId': empresaId});
    }

    debugPrint('--- MIGRAÇÃO CONCLUÍDA ---');
  }
}
