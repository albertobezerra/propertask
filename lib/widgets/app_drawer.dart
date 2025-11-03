// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ADICIONE
import 'package:firebase_auth/firebase_auth.dart';
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

// lib/widgets/app_drawer.dart
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

        final cargo = usuario.cargo.toUpperCase();

        return Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: const Text(
                  'Propertask',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(user.email ?? 'Usuário'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    user.email?.isNotEmpty == true
                        ? user.email![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(fontSize: 40, color: Colors.blue),
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                ),
              ),

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
                  SystemChannels.textInput.invokeMethod('TextInput.hide');
                  await Future.delayed(const Duration(milliseconds: 100));
                  await FirebaseAuth.instance.signOut();
                  // AppState será limpo no AuthWrapper
                },
              ),
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        }
      },
    );
  }
}
