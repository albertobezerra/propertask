// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:propertask/core/models/propriedade.dart';
import 'package:propertask/core/models/tarefa.dart';
import 'package:propertask/core/models/usuario.dart';

class FirestoreService {
  final String empresaId;
  final _db = FirebaseFirestore.instance;

  FirestoreService({required this.empresaId});

  // PROPRIEDADES
  CollectionReference get _props =>
      _db.collection('empresas').doc(empresaId).collection('propriedades');

  Stream<List<Propriedade>> getPropriedades() => _props.snapshots().map(
    (s) => s.docs
        .where((doc) => doc.data() != null)
        .map(Propriedade.fromFirestore)
        .toList(),
  );

  Future<void> addPropriedade(Propriedade p) => _props.add(p.toFirestore());
  Future<void> updatePropriedade(Propriedade p) =>
      _props.doc(p.id).update(p.toFirestore());
  Future<void> deletePropriedade(String id) => _props.doc(id).delete();

  // TAREFAS
  CollectionReference get _tarefas =>
      _db.collection('empresas').doc(empresaId).collection('tarefas');

  Stream<List<Tarefa>> getTarefasDoDia(DateTime dia, String uid, String cargo) {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fim = inicio.add(const Duration(days: 1));

    final query = _tarefas
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fim));

    if (cargo == 'LIMPEZA') {
      return query
          .where('responsavelId', isEqualTo: uid)
          .snapshots()
          .map(
            (s) => s.docs
                .where((doc) => doc.data() != null)
                .map(Tarefa.fromFirestore)
                .toList(),
          );
    } else {
      return query.snapshots().map(
        (s) => s.docs
            .where((doc) => doc.data() != null)
            .map(Tarefa.fromFirestore)
            .toList(),
      );
    }
  }

  Future<void> addTarefa(Tarefa t) => _tarefas.add(t.toFirestore());
  Future<void> updateTarefa(Tarefa t) =>
      _tarefas.doc(t.id).update(t.toFirestore());
  Future<void> deleteTarefa(String id) => _tarefas.doc(id).delete();

  // USUÁRIOS
  CollectionReference get _usuarios =>
      _db.collection('empresas').doc(empresaId).collection('usuarios');

  Stream<List<Usuario>> getUsuarios() => _usuarios.snapshots().map(
    (s) => s.docs
        .where((doc) => doc.data() != null)
        .map(Usuario.fromFirestore)
        .toList(),
  );

  Future<void> addUsuario(Usuario u) =>
      _usuarios.doc(u.id).set(u.toFirestore());
  Future<void> updateUsuario(Usuario u) =>
      _usuarios.doc(u.id).update(u.toFirestore());
}
