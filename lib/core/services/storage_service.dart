import 'dart:io';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- UPLOADS (Seus métodos originais) ---

  // Foto de perfil
  Future<String> uploadUserProfileImageBytes(
    Uint8List bytes,
    String empresaId,
    String userId,
  ) async {
    final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(
      'empresas/$empresaId/perfil/$userId/$filename',
    );
    final snapshot = await ref.putData(bytes);
    return await snapshot.ref.getDownloadURL();
  }

  // Imagem de PROPRIEDADE
  Future<String> uploadPropriedadeImage(
    XFile file,
    String empresaId,
    String propriedadeId,
  ) async {
    final ref = _storage.ref().child(
      'empresas/$empresaId/propriedades/$propriedadeId/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );
    final snapshot = await ref.putFile(File(file.path));
    return await snapshot.ref.getDownloadURL();
  }

  // Imagem de TAREFA
  Future<String> uploadTarefaImage(
    XFile file,
    String empresaId,
    String propriedadeId,
    String tarefaId,
  ) async {
    final ref = _storage.ref().child(
      'empresas/$empresaId/tarefas/$propriedadeId/$tarefaId/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );
    final snapshot = await ref.putFile(File(file.path));
    return await snapshot.ref.getDownloadURL();
  }

  // --- EXCLUSÃO (Novo Método) ---

  /// Deleta um arquivo específico do Storage usando a URL
  Future<void> deleteImageByUrl(String url) async {
    // Verificação de segurança: só tenta deletar se for do Firebase Storage
    if (!url.contains('firebasestorage')) return;

    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      debugPrint('Imagem deletada do Storage com sucesso: $url');
    } catch (e) {
      // Se der erro (ex: arquivo não existe mais), apenas loga e segue a vida
      debugPrint(
        'Aviso: Erro ao tentar deletar imagem do Storage (pode já não existir): $e',
      );
    }
  }
}
