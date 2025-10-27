import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao fazer login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> initializeStructure() async {
    try {
      final doc = await _firestore
          .collection('propertask')
          .doc('config')
          .collection('init')
          .doc('initialized')
          .get();
      if (doc.exists) {
        debugPrint('! Estrutura já inicializada. Pulando criação.');
        return;
      }

      await _firestore
          .collection('propertask')
          .doc('config')
          .collection('init')
          .doc('initialized')
          .set({'value': true});
      debugPrint('✅ Estrutura inicializada');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar estrutura: $e');
      rethrow;
    }
  }
}
