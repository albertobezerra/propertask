// lib/core/services/setup_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SetupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _rootCollection = 'propertask'; // Coleção raiz
  static const String _rootDoc = 'config'; // Documento raiz
  static const String _versionKey = 'db_version';
  static const int _currentVersion = 3;

  Future<void> initialize() async {
    try {
      debugPrint('Inicializando estrutura em $_rootCollection/$_rootDoc...');
      await _ensureRootExists();
      await _runMigrations();
      debugPrint('Setup concluído com sucesso!');
    } catch (e) {
      debugPrint('Erro no setup: $e');
      rethrow;
    }
  }

  Future<void> _ensureRootExists() async {
    final rootRef = _db.collection(_rootCollection).doc(_rootDoc);
    final doc = await rootRef.get();

    if (doc.exists) {
      debugPrint('Raiz $_rootCollection/$_rootDoc já existe.');
      return;
    }

    debugPrint('Criando documento raiz...');
    await rootRef.set({
      'nome': 'Kilometros Ecléticos',
      'criadoEm': FieldValue.serverTimestamp(),
      'ativa': true,
      _versionKey: 0,
    });
  }

  Future<void> _runMigrations() async {
    final rootRef = _db.collection(_rootCollection).doc(_rootDoc);
    final doc = await rootRef.get();
    final currentVersion = doc[_versionKey] as int? ?? 0;

    if (currentVersion >= _currentVersion) {
      debugPrint('Banco já atualizado (v$currentVersion).');
      return;
    }

    debugPrint('Aplicando migrações v$currentVersion → v$_currentVersion...');

    for (int v = currentVersion + 1; v <= _currentVersion; v++) {
      await _applyMigration(v);
    }

    await rootRef.update({_versionKey: _currentVersion});
    debugPrint('Migrações concluídas! Versão: $_currentVersion');
  }

  Future<void> _applyMigration(int version) async {
    final basePath = _rootCollection;

    switch (version) {
      case 1:
        final tarefas = await _db
            .collection('$basePath/tarefas/tarefas')
            .where('status', isEqualTo: 'concluida')
            .get();

        for (final doc in tarefas.docs) {
          if (doc['concluidaEm'] == null) {
            await doc.reference.update({'concluidaEm': doc['data']});
          }
        }
        break;

      case 2:
        final props = await _db
            .collection('$basePath/propriedades/propriedades')
            .get();

        for (final doc in props.docs) {
          final data = doc.data();
          final updates = <String, dynamic>{};
          if (data['tipologia'] == null) updates['tipologia'] = 'T1';
          if (data['acesso'] == null) updates['acesso'] = 'chave';
          if (updates.isNotEmpty) {
            await doc.reference.update(updates);
          }
        }
        break;

      case 3:
        await _db.doc('$basePath/ponto').set({'inicializado': true});
        break;
    }
  }
}
