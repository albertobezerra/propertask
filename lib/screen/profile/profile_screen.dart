// lib/screen/profile/profile_screen.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:propertask/widgets/app_drawer.dart';
// Descomente quando for usar Cloudinary de fato
// import 'package:cloudinary_public/cloudinary_public.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _localAvatarPath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Carrega avatar local salvo anteriormente (se existir)
    _loadLocalAvatar();
  }

  Future<void> _loadLocalAvatar() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Procura um arquivo salvo previamente com nome fixo
      final docsDir = await getApplicationDocumentsDirectory();
      final candidate = File('${docsDir.path}/avatar_${user.uid}.jpg');
      if (await candidate.exists()) {
        if (!mounted) return;
        setState(() => _localAvatarPath = candidate.path);
      }
    } catch (_) {
      // silencioso
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Copia para pasta do app com nome determinístico (persiste entre execuções)
      final docsDir = await getApplicationDocumentsDirectory();
      final dest = File('${docsDir.path}/avatar_${user.uid}.jpg');
      await File(picked.path).copy(dest.path);

      if (!mounted) return;
      setState(() => _localAvatarPath = dest.path);

      messenger.showSnackBar(
        const SnackBar(content: Text('Foto atualizada com sucesso.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editarTelefone(
    DocumentReference<Map<String, dynamic>> userRef,
    String? atual,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: atual ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar telefone'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '(DDD) 99999-9999',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await userRef.update({'telefone': controller.text.trim()});
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Telefone atualizado.')),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Erro: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // PREPARADO para futura integração Cloudinary (não usado agora).
  // Preencha CLOUD_NAME e UPLOAD_PRESET e chame dentro do _pickAvatar quando desejar.
  // Future<void> _uploadToCloudinary(File file, DocumentReference<Map<String, dynamic>> userRef) async {
  //   try {
  //     final cloudinary = CloudinaryPublic('CLOUD_NAME', 'UPLOAD_PRESET', cache: false);
  //     final res = await cloudinary.uploadFile(
  //       CloudinaryFile.fromFile(file.path, folder: 'propertask/avatars'),
  //     );
  //     await userRef.update({'fotoUrl': res.secureUrl});
  //   } catch (e) {
  //     // Trate erro conforme necessário
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final userRef = FirebaseFirestore.instance
        .collection('propertask')
        .doc('usuarios')
        .collection('usuarios')
        .doc(user.uid)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/perfil'),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          final data = snapshot.data!.data()!;
          final nome = (data['nome'] ?? '').toString();
          final email = (data['email'] ?? user.email ?? '').toString();
          final cargo = (data['cargo'] ?? 'Colaborador').toString();
          final telefone = (data['telefone'] ?? '').toString();
          final fotoUrl = (data['fotoUrl'] ?? '')
              .toString(); // futuro (Cloudinary)

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: _localAvatarPath != null
                          ? FileImage(File(_localAvatarPath!))
                          : (fotoUrl.isNotEmpty
                                ? NetworkImage(fotoUrl) as ImageProvider
                                : null),
                      child: (_localAvatarPath == null && fotoUrl.isEmpty)
                          ? Text(
                              nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 50,
                                color: Colors.blue,
                              ),
                            )
                          : null,
                    ),
                    PopupMenuButton<String>(
                      icon: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue.shade700,
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      onSelected: (v) async {
                        if (v == 'camera') {
                          await _pickAvatar(ImageSource.camera);
                        } else if (v == 'galeria') {
                          await _pickAvatar(ImageSource.gallery);
                        } else if (v == 'remover') {
                          // Remove imagem local
                          if (_localAvatarPath != null) {
                            try {
                              final f = File(_localAvatarPath!);
                              if (await f.exists()) await f.delete();
                            } catch (_) {}
                            if (!mounted) return;
                            setState(() => _localAvatarPath = null);
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'camera', child: Text('Câmera')),
                        PopupMenuItem(value: 'galeria', child: Text('Galeria')),
                        PopupMenuItem(
                          value: 'remover',
                          child: Text('Remover foto'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _info('Nome', nome, icon: Icons.person),
              _info('Email', email, icon: Icons.email),
              _info('Cargo', cargo, icon: Icons.work),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone, color: Colors.blue),
                  title: const Text(
                    'Telefone',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(telefone.isEmpty ? 'Não informado' : telefone),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editarTelefone(userRef, telefone),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // (Opcional) Mostrar origem atual
              // Text('Foto local: ${_localAvatarPath ?? "-"}'),
            ],
          );
        },
      ),
    );
  }

  Widget _info(String label, String value, {required IconData icon}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value.isEmpty ? 'Não informado' : value),
      ),
    );
  }
}
