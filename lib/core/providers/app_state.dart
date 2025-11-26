import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:propertask/core/models/usuario.dart';

class AppState with ChangeNotifier {
  User? _user;
  Usuario? _usuario;
  String? _senhaUsuario;
  String? _empresaId;

  User? get user => _user;
  Usuario? get usuario => _usuario;
  String? get senhaUsuario => _senhaUsuario;
  String? get empresaId => _empresaId;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  void setSenhaUsuario(String senha) {
    _senhaUsuario = senha;
    notifyListeners();
  }

  void setEmpresaId(String empresaId) {
    _empresaId = empresaId;
    notifyListeners();
  }

  // Use caminho direto SEM collectionGroup
  Future<void> carregarPerfil(User user) async {
    _usuario = null;
    _empresaId = null;

    // Troque aqui: se seu app está apenas para UMA empresa no momento,
    // use empresa fixa, depois torne dinâmico conforme produto SaaS.

    final empresaId =
        _empresaId ?? 'Kilometros'; // Ou outra lógica se múltiplas empresas
    try {
      final doc = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(empresaId)
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        _usuario = Usuario.fromFirestore(doc);
        _empresaId = empresaId; // já fica disponível!
      } else {
        _usuario = null;
        _empresaId = null;
      }
    } catch (_) {
      _usuario = null;
      _empresaId = null;
    }
    notifyListeners();
  }

  Future<void> atualizarFotoUsuario(String fotoUrl) async {
    if (_usuario == null || _user == null || _empresaId == null) return;

    _usuario = Usuario(
      id: _usuario!.id,
      empresaId: _usuario!.empresaId,
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
        .collection('empresas')
        .doc(_empresaId)
        .collection('usuarios')
        .doc(_user!.uid)
        .update({'fotoUrl': fotoUrl});
  }

  void limpar() {
    _user = null;
    _usuario = null;
    _senhaUsuario = null;
    _empresaId = null;
    notifyListeners();
  }
}
