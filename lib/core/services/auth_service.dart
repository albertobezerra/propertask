import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Login e verifica se o usuário está na coleção 'propertask/usuarios'
  Future<bool> login({required String email, required String password}) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCred.user!.uid;
      debugPrint('🔍 Verificando usuário com UID: $uid');

      final userDoc = await _firestore
          .collection('propertask')
          .doc('usuarios')
          .collection('usuarios')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        debugPrint('✅ Usuário encontrado: ${userDoc['nome']}');
        return true;
      }

      debugPrint('⚠️ Usuário não encontrado na coleção usuarios.');
      return false;
    } catch (e) {
      debugPrint('❌ Erro no login: $e');
      return false;
    }
  }

  /// Inicializa a estrutura base do Firestore
  Future<void> initializeStructure() async {
    try {
      final usuariosRef = _firestore
          .collection('propertask')
          .doc('usuarios')
          .collection('usuarios');
      final propriedadesRef = _firestore
          .collection('propertask')
          .doc('propriedades')
          .collection('propriedades');
      final tarefasRef = _firestore
          .collection('propertask')
          .doc('tarefas')
          .collection('tarefas');

      // Verifica se a estrutura já existe
      final configDoc = await _firestore
          .collection('propertask')
          .doc('config')
          .get();
      if (configDoc.exists) {
        debugPrint('⚠️ Estrutura já inicializada. Pulando criação.');
        return;
      }

      debugPrint('🏗️ Criando estrutura base para propertask...');

      // Cria documento de configuração
      await _firestore.collection('propertask').doc('config').set({
        'nome': 'Kilometros Ecléticos',
        'criadoEm': FieldValue.serverTimestamp(),
        'ativa': true,
      });
      debugPrint('✅ Documento de configuração criado');

      // Cria documento base para usuarios
      await _firestore.collection('propertask').doc('usuarios').set({
        'inicializado': true,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Documento base de usuarios criado');

      // Cria usuário coordenador
      await usuariosRef.doc('1HxCrQXAkseNJ8gtIS3PYVoCmmW2').set({
        'uid': '1HxCrQXAkseNJ8gtIS3PYVoCmmW2',
        'nome': 'Alberto Bezerra',
        'email': 'albertofbezerra@gmail.com',
        'cargo': 'Coordenador',
        'criadoEm': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Usuário coordenador criado');

      // Cria documento base para propriedades
      await _firestore.collection('propertask').doc('propriedades').set({
        'inicializado': true,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Documento base de propriedades criado');

      // Cria propriedade de exemplo
      final propDoc = await propriedadesRef.add({
        'nome': 'Propriedade Exemplo',
        'localizacao': 'A definir',
        'criadoEm': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Propriedade criada com ID: ${propDoc.id}');

      // Cria documento base para tarefas
      await _firestore.collection('propertask').doc('tarefas').set({
        'inicializado': true,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Documento base de tarefas criado');

      // Cria tarefa de exemplo
      await tarefasRef.add({
        'titulo': 'Tarefa de Exemplo',
        'status': 'pendente',
        'propriedadeId': propDoc.id,
        'responsavelId': '1HxCrQXAkseNJ8gtIS3PYVoCmmW2',
        'criadoEm': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Tarefa de exemplo criada');

      debugPrint('✅ Estrutura inicial criada com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar estrutura: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      debugPrint('✅ Logout realizado com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao fazer logout: $e');
    }
  }

  User? get currentUser => _auth.currentUser;
}
