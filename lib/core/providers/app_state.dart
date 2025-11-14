import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:propertask/core/models/usuario.dart'; // Importa o modelo completo!

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

  Future<void> atualizarFotoUsuario(String fotoUrl) async {
    if (_usuario == null || _user == null) return;
    // Cria um novo Usuario atualizado
    _usuario = Usuario(
      id: _usuario!.id,
      nome: _usuario!.nome,
      email: _usuario!.email,
      cargo: _usuario!.cargo,
      telefone: _usuario!.telefone,
      fotoUrl: fotoUrl,
      criadoEm: _usuario!.criadoEm,
      ativo: _usuario!.ativo,
    );
    notifyListeners();
    await FirebaseFirestore.instance
        .collection('propertask')
        .doc('usuarios')
        .collection('usuarios')
        .doc(_user!.uid)
        .update({'fotoUrl': fotoUrl});
  }

  void limpar() {
    _user = null;
    _usuario = null;
    _senhaUsuario = null;
    notifyListeners();
  }
}
