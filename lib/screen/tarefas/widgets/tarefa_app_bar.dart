import 'package:flutter/material.dart';

class TarefaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String tipo;
  final String propriedadeNome;

  const TarefaAppBar({
    super.key,
    required this.tipo,
    required this.propriedadeNome,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: cs.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          _getTipoIcon(tipo, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$propriedadeNome - ${_formatTipo(tipo)}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _formatTipo(String tipo) {
    switch (tipo) {
      case 'limpeza':
        return 'Limpeza';
      case 'entrega':
        return 'Entrega';
      case 'recolha':
        return 'Recolha';
      case 'manutencao':
        return 'Manutenção';
      default:
        return tipo;
    }
  }

  Icon _getTipoIcon(String tipo, {Color color = Colors.black}) {
    switch (tipo) {
      case 'limpeza':
        return Icon(Icons.cleaning_services, color: color);
      case 'entrega':
        return Icon(Icons.assignment_turned_in_outlined, color: color);
      case 'recolha':
        return Icon(Icons.move_to_inbox, color: color);
      case 'manutencao':
        return Icon(Icons.build, color: color);
      default:
        return Icon(Icons.help_outline, color: color);
    }
  }
}
