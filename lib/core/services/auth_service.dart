// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';

class AuthService {
  // LOGIN simples: só autentica; bloqueio de inativo fica no AuthWrapper.
  static Future<bool> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } catch (e) {
      debugPrint('ERRO LOGIN: $e');
      return false;
    }
  }

  static Future<void> esqueciSenha(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // LOGOUT
  static Future<void> logout(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.limpar();
    await FirebaseAuth.instance.signOut();
  }
}
