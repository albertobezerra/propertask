import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:propertask/core/models/propriedade.dart';
import 'package:propertask/core/models/tarefa.dart';

class FirestoreService {
  final CollectionReference _propriedades = FirebaseFirestore.instance
      .collection('propertask')
      .doc('propriedades')
      .collection('propriedades');
  final CollectionReference _tarefas = FirebaseFirestore.instance
      .collection('propertask')
      .doc('tarefas')
      .collection('tarefas');

  Future<void> addPropriedade(Propriedade propriedade) async {
    await _propriedades.add(propriedade.toFirestore());
  }

  Stream<List<Propriedade>> getPropriedades() {
    return _propriedades
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Propriedade.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addTarefa(Tarefa tarefa) async {
    await _tarefas.add(tarefa.toFirestore());
  }

  Stream<List<Tarefa>> getTarefas(String propriedadeId) {
    return _tarefas
        .where('propriedadeId', isEqualTo: propriedadeId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Tarefa.fromFirestore(doc)).toList(),
        );
  }
}
