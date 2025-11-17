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

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

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
          child: Container(
            decoration: const BoxDecoration(color: Color(0xFF6AB090)),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 44,
                                  color: Color(0xFF6AB090),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    cargo,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.67),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 18,
                      ),
                      children: [
                        if (currentRoute != '/dashboard')
                          _drawerItem(
                            context,
                            Icons.dashboard,
                            'Dashboard',
                            const DashboardScreen(),
                            '/dashboard',
                          ),
                        if (Permissions.podeVerTarefas(cargo) &&
                            currentRoute != '/tarefas')
                          _drawerItem(
                            context,
                            Icons.task,
                            'Tarefas',
                            const TarefasScreen(),
                            '/tarefas',
                          ),
                        if (currentRoute != '/perfil')
                          _drawerItem(
                            context,
                            Icons.person,
                            'Perfil',
                            const ProfileScreen(),
                            '/perfil',
                          ),
                        if (currentRoute != '/ponto')
                          _drawerItem(
                            context,
                            Icons.access_time,
                            'Ponto',
                            const PontoScreen(),
                            '/ponto',
                          ),
                        if (Permissions.podeVerPropriedades(cargo) &&
                            currentRoute != '/propriedades')
                          _drawerItem(
                            context,
                            Icons.home,
                            'Propriedades',
                            const PropriedadesScreen(),
                            '/propriedades',
                          ),
                        if (Permissions.podeVerLavanderia(cargo) &&
                            currentRoute != '/lavanderia')
                          _drawerItem(
                            context,
                            Icons.local_laundry_service,
                            'Lavanderia',
                            const LavanderiaScreen(),
                            '/lavanderia',
                          ),
                        if (Permissions.podeVerRelatorios(cargo) &&
                            currentRoute != '/relatorios')
                          _drawerItem(
                            context,
                            Icons.bar_chart,
                            'Relatórios',
                            const RelatoriosScreen(),
                            '/relatorios',
                          ),
                        if (Permissions.podeVerEquipe(cargo) &&
                            currentRoute != '/equipe')
                          _drawerItem(
                            context,
                            Icons.group,
                            'Equipe',
                            const EquipeScreen(),
                            '/equipe',
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                        await AuthService.logout(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String label,
    Widget screen,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 26),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      horizontalTitleGap: 10,
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
    );
  }
}
