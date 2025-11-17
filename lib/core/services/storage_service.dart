import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Foto de perfil (com upload de bytes já comprimido)
  Future<String> uploadUserProfileImageBytes(
    Uint8List bytes,
    String userId,
  ) async {
    final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('propertask/perfil/$userId/$filename');
    final snapshot = await ref.putData(bytes);
    return await snapshot.ref.getDownloadURL();
  }

  // Exclui foto anterior
  Future<void> deleteFileFromUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      /* ignore errors */
    }
  }

  // Métodos antigos mantidos para propriedade/tarefa
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
