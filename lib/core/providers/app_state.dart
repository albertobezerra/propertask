// lib/core/providers/app_state.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:propertask/core/models/usuario.dart';

class AppState with ChangeNotifier {
  User? _user;
  Usuario? _usuario;
  bool _isDarkMode = false;

  User? get user => _user;
  Usuario? get usuario => _usuario;
  bool get isDarkMode => _isDarkMode;

  // MUDANÇA AQUI: Future<void>
  Future<void> setUser(User? user) async {
    _user = user;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('propertask')
          .doc('usuarios')
          .collection('usuarios')
          .doc(user.uid)
          .get();

      _usuario = doc.exists ? Usuario.fromFirestore(doc) : null;
    } else {
      _usuario = null;
    }
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
