import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'dashboard_empregado_screen.dart';
import 'dashboard_coord_screen.dart';
import 'dashboard_sup_screen.dart';
import 'dashboard_ceo_screen.dart';
import 'dashboard_dev_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final usuario = appState.usuario;
    if (usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cargo = usuario.cargo?.toUpperCase() ?? '';

    switch (cargo) {
      case 'LIMPEZA':
      case 'LAVANDERIA':
        return const DashboardEmpregadoScreen();
      case 'COORDENADOR':
        return const DashboardCoordScreen();
      case 'SUPERVISOR':
        return const DashboardSupScreen();
      case 'CEO':
        return const DashboardCeoScreen();
      case 'DEV':
        return const DashboardDevScreen();
      default:
        return const DashboardEmpregadoScreen(); // fallback
    }
  }
}
