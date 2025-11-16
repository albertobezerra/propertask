import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/widgets/app_drawer.dart'; // Troque pelo seu Drawer

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

        final avatarUrl = usuario.fotoUrl;
        final nome = usuario.nome;
        final departamento = usuario.cargo;
        final telefone = usuario.telefone ?? '';
        final email = usuario.email;

        return Scaffold(
          backgroundColor: const Color(
            0xFF1A5B53,
          ), // fundo do app igual ao mockup
          drawer: AppDrawer(currentRoute: '/perfil'), // Drawer integrado!
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
                    color: Color(0xFF3AB09C), // verde teal mockup
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
                        const SizedBox(height: 40),
                        // Card branco arredondado com dados
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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    nome,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF133E35),
                                      fontSize: 22,
                                    ),
                                  ),
                                  if (telefone.isNotEmpty)
                                    Text(
                                      telefone,
                                      style: TextStyle(
                                        color: Color(0xFF5A9E8B),
                                        fontSize: 14,
                                      ),
                                    ),
                                  if (departamento.isNotEmpty)
                                    Text(
                                      departamento,
                                      style: TextStyle(
                                        color: Color(0xFF45C3B7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.black38,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Avatar, fora do card branco
                            Positioned(
                              top: -43,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: CircleAvatar(
                                  radius: 43,
                                  backgroundColor: Color(0xFF3AB09C),
                                  backgroundImage:
                                      (avatarUrl != null &&
                                          avatarUrl.isNotEmpty)
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl == null || avatarUrl.isEmpty
                                      ? Icon(
                                          Icons.person,
                                          size: 46,
                                          color: Colors.white,
                                        )
                                      : null,
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
                        SizedBox(height: 36),
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

  // Card flat de opção igual ao mockup
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
        boxShadow: [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
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
