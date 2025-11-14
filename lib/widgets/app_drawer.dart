import 'package:flutter/material.dart';
import 'package:propertask/core/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';
import 'package:propertask/screen/dashboard/dashboard_screen.dart';
import 'package:propertask/screen/profile/profile_screen.dart';
import 'package:propertask/screen/propriedades/propriedades_screen.dart';
import 'package:propertask/screen/tarefas/tarefas_screen.dart';
import 'package:propertask/screen/relatorios/relatorios_screen.dart';
import 'package:propertask/screen/ponto/ponto_screen.dart';
import 'package:propertask/screen/lavanderia/lavanderia_screen.dart';
import 'package:propertask/screen/equipe/equipe_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:propertask/core/services/storage_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  Future<void> _updateAvatar(BuildContext context, AppState appState) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final urls = await StorageService().uploadImages([image]);
      if (!context.mounted) return;
      if (urls.isNotEmpty) {
        await appState.atualizarFotoUsuario(urls.first);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto atualizada com sucesso!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final user = appState.user;
        final usuario = appState.usuario;

        if (user == null || usuario == null) {
          return const Drawer(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final avatarUrl = usuario.fotoUrl;
        final name = usuario.nome;
        final cargo = usuario.cargo.toUpperCase();

        return Drawer(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(38),
                    bottomRight: Radius.circular(38),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _updateAvatar(context, appState),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                          ),
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            child: Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      cargo,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (currentRoute != '/dashboard')
                      _item(
                        context,
                        Icons.dashboard,
                        'Dashboard',
                        const DashboardScreen(),
                        '/dashboard',
                      ),
                    if (currentRoute != '/perfil')
                      _item(
                        context,
                        Icons.person,
                        'Perfil',
                        const ProfileScreen(),
                        '/perfil',
                      ),
                    if (currentRoute != '/ponto')
                      _item(
                        context,
                        Icons.access_time,
                        'Ponto',
                        const PontoScreen(),
                        '/ponto',
                      ),
                    if (Permissions.podeVerPropriedades(cargo) &&
                        currentRoute != '/propriedades')
                      _item(
                        context,
                        Icons.home,
                        'Propriedades',
                        const PropriedadesScreen(),
                        '/propriedades',
                      ),
                    if (Permissions.podeVerTarefas(cargo) &&
                        currentRoute != '/tarefas')
                      _item(
                        context,
                        Icons.task,
                        'Tarefas',
                        const TarefasScreen(),
                        '/tarefas',
                      ),
                    if (Permissions.podeVerLavanderia(cargo) &&
                        currentRoute != '/lavanderia')
                      _item(
                        context,
                        Icons.local_laundry_service,
                        'Lavanderia',
                        const LavanderiaScreen(),
                        '/lavanderia',
                      ),
                    if (Permissions.podeVerRelatorios(cargo) &&
                        currentRoute != '/relatorios')
                      _item(
                        context,
                        Icons.bar_chart,
                        'Relatórios',
                        const RelatoriosScreen(),
                        '/relatorios',
                      ),
                    if (Permissions.podeVerEquipe(cargo) &&
                        currentRoute != '/equipe')
                      _item(
                        context,
                        Icons.group,
                        'Equipe',
                        const EquipeScreen(),
                        '/equipe',
                      ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  await AuthService.logout(context);
                },
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
    );
  }
}
