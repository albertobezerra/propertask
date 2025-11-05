// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:propertask/screen/login/login_screen.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // LOGIN
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('ERRO LOGIN: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('ERRO GERAL: $e');
      return false;
    }
  }

  // LOGOUT GLOBAL (FORÇA TELA DE LOGIN)
  static Future<void> logout(BuildContext context) async {
    await _auth.signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false, // REMOVE TODAS AS TELAS
      );
    }
  }
}
