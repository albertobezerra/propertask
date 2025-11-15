import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Foto de perfil
  Future<String> uploadUserProfileImage(XFile file, String userId) async {
    final ref = _storage.ref().child(
      'propertask/perfil/$userId/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );
    final snapshot = await ref.putFile(File(file.path));
    return await snapshot.ref.getDownloadURL();
  }

  // Foto propriedade
  Future<String> uploadPropriedadeImage(
    XFile file,
    String propriedadeId,
  ) async {
    final ref = _storage.ref().child(
      'propertask/propriedades/$propriedadeId/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );
    final snapshot = await ref.putFile(File(file.path));
    return await snapshot.ref.getDownloadURL();
  }

  // Foto tarefa
  Future<String> uploadTarefaImage(
    XFile file,
    String propriedadeId,
    String tarefaId,
  ) async {
    final ref = _storage.ref().child(
      'propertask/tarefas/$propriedadeId/$tarefaId/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );
    final snapshot = await ref.putFile(File(file.path));
    return await snapshot.ref.getDownloadURL();
  }
}
