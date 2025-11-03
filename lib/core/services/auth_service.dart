import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
}
