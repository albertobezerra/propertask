// lib/core/providers/app_state.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:propertask/core/models/usuario.dart';

class AppState with ChangeNotifier {
  User? _user;
  Usuario? _usuario;

  User? get user => _user;
  Usuario? get usuario => _usuario;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> carregarPerfil(User user) async {
    _usuario = null;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('propertask')
          .doc('usuarios')
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _usuario = Usuario.fromFirestore(doc);
      } else {
        _usuario = null;
      }
    } catch (_) {
      _usuario = null;
    }

    notifyListeners();
  }

  void limpar() {
    _user = null;
    _usuario = null;
    notifyListeners();
  }
}
