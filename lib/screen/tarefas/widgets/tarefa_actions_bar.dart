import 'package:flutter/material.dart';

class TarefaActionsBar extends StatelessWidget {
  final bool loading;
  final bool podeIniciar;
  final bool podeConcluir;
  final bool podeReabrir;
  final VoidCallback onIniciar;
  final VoidCallback onConcluir;
  final VoidCallback onReabrir;

  const TarefaActionsBar({
    super.key,
    required this.loading,
    required this.podeIniciar,
    required this.podeConcluir,
    required this.podeReabrir,
    required this.onIniciar,
    required this.onConcluir,
    required this.onReabrir,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        if (podeIniciar)
          Expanded(
            child: ElevatedButton(
              onPressed: onIniciar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Iniciar tarefa'),
            ),
          ),
        if (podeConcluir)
          Expanded(
            child: ElevatedButton(
              onPressed: onConcluir,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Concluir tarefa'),
            ),
          ),
        if (podeReabrir)
          Expanded(
            child: ElevatedButton(
              onPressed: onReabrir,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Reabrir'),
            ),
          ),
      ],
    );
  }
}
