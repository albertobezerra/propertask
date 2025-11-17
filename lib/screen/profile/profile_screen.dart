import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:propertask/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/services/storage_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _updateAvatar(
    BuildContext context,
    String userId,
    String? oldFotoUrl,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }
      try {
        final imgBytes = await picked.readAsBytes();
        final compressed = await FlutterImageCompress.compressWithList(
          imgBytes,
          minWidth: 400,
          minHeight: 400,
          quality: 80,
        );
        if (oldFotoUrl != null && oldFotoUrl.isNotEmpty) {
          await StorageService().deleteFileFromUrl(oldFotoUrl);
        }
        if (!context.mounted) return;
        final url = await StorageService().uploadUserProfileImageBytes(
          Uint8List.fromList(compressed),
          userId,
        );
        if (!context.mounted) return;
        await Provider.of<AppState>(
          context,
          listen: false,
        ).atualizarFotoUsuario(url);
        if (!context.mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto atualizada!')));
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final usuario = appState.usuario;
        if (usuario == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final avatarUrl = usuario.fotoUrl ?? '';

        return Scaffold(
          backgroundColor: const Color(0xFF1A5B53),
          drawer: AppDrawer(currentRoute: '/perfil'),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: "Abrir menu",
              ),
            ),
            centerTitle: true,
            title: const Text(
              'Perfil',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Stack(
            children: [
              Positioned(
                top: -120,
                left: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Color(0xFF3AB09C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 80),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(
                                top: 64,
                                bottom: 22,
                                left: 20,
                                right: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    usuario.nome,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF133E35),
                                      fontSize: 22,
                                    ),
                                  ),
                                  if ((usuario.telefone ?? '').isNotEmpty)
                                    Text(
                                      usuario.telefone ?? '',
                                      style: TextStyle(
                                        color: Color(0xFF5A9E8B),
                                        fontSize: 14,
                                      ),
                                    ),
                                  if ((usuario.cargo).isNotEmpty)
                                    Text(
                                      usuario.cargo,
                                      style: TextStyle(
                                        color: Color(0xFF45C3B7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  Text(
                                    usuario.email,
                                    style: TextStyle(
                                      color: Colors.black38,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Positioned(
                              top: -66,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      height: 120,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(32),
                                        child: avatarUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: avatarUrl,
                                                placeholder: (ctx, url) =>
                                                    Container(
                                                      color: Color(0xFF3AB09C),
                                                      child: Icon(
                                                        Icons.person,
                                                        size: 46,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                errorWidget:
                                                    (ctx, url, error) =>
                                                        Container(
                                                          color: Color(
                                                            0xFF3AB09C,
                                                          ),
                                                          child: Icon(
                                                            Icons.person,
                                                            size: 46,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                color: Color(0xFF3AB09C),
                                                child: Icon(
                                                  Icons.person,
                                                  size: 46,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _updateAvatar(
                                          context,
                                          usuario.id,
                                          usuario.fotoUrl,
                                        ),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Color(0xFF3AB09C),
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        cardOpcao(
                          icon: Icons.language,
                          label: "Idioma",
                          trailing: "Português",
                        ),
                        cardOpcao(icon: Icons.lock, label: "Alterar senha"),
                        cardOpcao(
                          icon: Icons.privacy_tip_outlined,
                          label: "Privacidade",
                        ),
                        cardOpcao(
                          icon: Icons.description_outlined,
                          label: "Termos de uso",
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3AB09C),
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {}, // Deslogar
                            child: Text(
                              "Sair",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget cardOpcao({
    required IconData icon,
    required String label,
    String? trailing,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF3AB09C), size: 26),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: trailing != null
            ? Text(
                trailing,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3AB09C),
                ),
              )
            : null,
        dense: true,
        visualDensity: VisualDensity.compact,
        onTap: () {},
      ),
    );
  }
}
