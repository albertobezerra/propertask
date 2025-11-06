// lib/core/providers/app_state.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Usuario {
  final String? email;
  final String? cargo;
  final bool ativo;

  Usuario({this.email, this.cargo, required this.ativo});

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Usuario(
      email: data['email'] as String?,
      cargo: data['cargo'] as String?,
      ativo: (data['ativo'] == true), // default false se null
    );
  }
}

class AppState with ChangeNotifier {
  User? _user;
  Usuario? _usuario;
  String? _senhaUsuario;

  User? get user => _user;
  Usuario? get usuario => _usuario;
  String? get senhaUsuario => _senhaUsuario;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  void setSenhaUsuario(String senha) {
    _senhaUsuario = senha;
    notifyListeners();
  }

  Future<void> carregarPerfil(User user) async {
    _usuario = null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('propertask')
          .doc('usuarios')
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        _usuario = Usuario.fromFirestore(doc);
      }
    } catch (_) {
      _usuario = null;
    }
    notifyListeners();
  }

  void limpar() {
    _user = null;
    _usuario = null;
    _senhaUsuario = null;
    notifyListeners();
  }
}
