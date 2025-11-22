import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';
import 'limpeza_tarefas_screen.dart';
import 'gestor_tarefas_screen.dart';

class TarefasScreen extends StatelessWidget {
  const TarefasScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final usuario = Provider.of<AppState>(context).usuario;
    final cargoEnum = usuario != null
        ? Permissions.cargoFromString(usuario.cargo)
        : Cargo.limpeza;

    if (cargoEnum == Cargo.limpeza || cargoEnum == Cargo.lavanderia) {
      return LimpezaTarefasScreen(usuarioId: usuario?.id ?? '');
    }
    if (cargoEnum == Cargo.dev ||
        cargoEnum == Cargo.ceo ||
        cargoEnum == Cargo.coordenador ||
        cargoEnum == Cargo.supervisor) {
      return GestorTarefasScreen();
    }
    return const Center(child: Text('Acesso não permitido.'));
  }
}
