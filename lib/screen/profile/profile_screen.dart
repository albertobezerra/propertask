import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; // <--- IMPORTANTE
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

// SEUS IMPORTS
import 'package:propertask/core/services/auth_service.dart';
import 'package:propertask/widgets/app_drawer.dart';
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
    // 1. Escolher imagem
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      // 2. Cortar imagem (CROP)
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Quadrado
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar Foto',
            // ignore: use_build_context_synchronously
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Ajustar Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return; // Cancelou o corte

      // 3. Loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      try {
        // 4. Comprimir
        final imgBytes = await File(croppedFile.path).readAsBytes();
        final compressed = await FlutterImageCompress.compressWithList(
          imgBytes,
          minWidth: 400,
          minHeight: 400,
          quality: 85,
        );

        // 5. Deletar antiga
        if (oldFotoUrl != null && oldFotoUrl.isNotEmpty) {
          await StorageService().deleteImageByUrl(oldFotoUrl);
        }

        if (!context.mounted) return;
        final empresaId = Provider.of<AppState>(
          context,
          listen: false,
        ).empresaId!;

        // 6. Upload
        final url = await StorageService().uploadUserProfileImageBytes(
          Uint8List.fromList(compressed),
          empresaId,
          userId,
        );

        if (!context.mounted) return;
        await Provider.of<AppState>(
          context,
          listen: false,
        ).atualizarFotoUsuario(url);

        if (!context.mounted) return;
        Navigator.of(context).pop(); // Fecha loading
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
    final cs = Theme.of(context).colorScheme;

    // Gradiente de fundo "Futurista Clean"
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [cs.primary.withValues(alpha: 0.05), Colors.white],
    );

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
          extendBodyBehindAppBar: true, // App bar transparente sobre o conteúdo
          drawer: AppDrawer(currentRoute: '/perfil'),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(
              color: cs.primary,
            ), // Ícone escuro/cor principal
            centerTitle: true,
            title: Text(
              'Meu Perfil',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                const SizedBox(height: 100), // Espaço para AppBar
                // --- AVATAR FUTURISTA ---
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(
                          4,
                        ), // Borda branca interna
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: cs.surfaceContainerHighest,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? CachedNetworkImageProvider(avatarUrl)
                              : null,
                          child: avatarUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: cs.primary.withValues(alpha: 0.5),
                                )
                              : null,
                        ),
                      ),
                      // Botão de editar flutuante
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- NOME E CARGO ---
                Center(
                  child: Column(
                    children: [
                      Text(
                        usuario.nome,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          usuario.cargo.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- LISTA DE OPÇÕES (CLEAN) ---
                _buildSectionTitle("Informações"),
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: usuario.email,
                ),
                _buildInfoTile(
                  icon: Icons.phone_outlined,
                  label: "Telefone",
                  value: usuario.telefone ?? '—',
                ),

                const SizedBox(height: 24),
                _buildSectionTitle("Configurações"),

                _buildActionTile(
                  icon: Icons.lock_outline,
                  label: "Alterar Senha",
                  onTap: () {}, // Implementar navegação
                ),
                _buildActionTile(
                  icon: Icons.language_outlined,
                  label: "Idioma",
                  trailing: "Português",
                  onTap: () {},
                ),
                _buildActionTile(
                  icon: Icons.description_outlined,
                  label: "Termos e Privacidade",
                  onTap: () {},
                ),

                const SizedBox(height: 40),

                // --- BOTÃO SAIR ---
                TextButton(
                  onPressed: () async {
                    await AuthService.logout(context);
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Sair da conta",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey[700], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(
              0xFF3AB09C,
            ).withValues(alpha: 0.1), // Ajuste para sua cor primária
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF3AB09C), size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: trailing != null
            ? Text(
                trailing,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
