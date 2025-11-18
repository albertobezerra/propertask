import 'package:flutter/material.dart';
import 'package:propertask/core/utils/formatters.dart';
import 'package:propertask/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/models/tarefa.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/services/firestore_service.dart';
import 'package:propertask/widgets/tarefa_card.dart';

class DashboardEmpregadoScreen extends StatefulWidget {
  const DashboardEmpregadoScreen({super.key});
  @override
  State<DashboardEmpregadoScreen> createState() =>
      _DashboardEmpregadoScreenState();
}

class _DashboardEmpregadoScreenState extends State<DashboardEmpregadoScreen> {
  DateTime _selectedDate = DateTime.now();

  List<DateTime> getFiveDayWindow(DateTime center) =>
      List.generate(5, (i) => center.subtract(Duration(days: 2 - i)));
  void _handleDateTap(DateTime clickedDate) {
    if (clickedDate.isAtSameMomentAs(_selectedDate)) return;
    setState(() => _selectedDate = clickedDate);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.user;
    final usuario = appState.usuario;
    final cs = Theme.of(context).colorScheme;

    if (user == null || usuario == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando usuário...'),
            ],
          ),
        ),
      );
    }

    final cargo = usuario.cargo.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.primary,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendar(cs),
            const SizedBox(height: 18),
            Expanded(
              child: StreamBuilder<List<Tarefa>>(
                stream: FirestoreService().getTarefasDoDia(
                  _selectedDate,
                  user.uid,
                  cargo,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _emptyState(cs);
                  }
                  final tarefas = snapshot.data!;
                  final emAberto = tarefas
                      .where(
                        (t) =>
                            t.status == 'em_aberto' || t.status == 'pendente',
                      )
                      .toList();
                  final emAndamento = tarefas
                      .where(
                        (t) =>
                            t.status == 'em_andamento' ||
                            t.status == 'progresso',
                      )
                      .toList();
                  final concluidas = tarefas
                      .where((t) => t.status == 'concluida')
                      .toList();
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildStatusSection(
                        'Em Aberto',
                        emAberto,
                        cs.primary,
                        Icons.hourglass_empty,
                      ),
                      _buildStatusSection(
                        'Em Andamento',
                        emAndamento,
                        cs.secondary,
                        Icons.play_arrow_rounded,
                      ),
                      _buildStatusSection(
                        'Concluída',
                        concluidas,
                        cs.primaryContainer, // Verde CLARINHO do theme
                        Icons.check_circle,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 58,
            color: cs.secondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 15),
          Text(
            'Nenhuma tarefa para este dia',
            style: TextStyle(fontSize: 18, color: cs.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(ColorScheme cs) {
    final days = getFiveDayWindow(_selectedDate);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: days.map((date) {
        final isSelected =
            date.day == _selectedDate.day &&
            date.month == _selectedDate.month &&
            date.year == _selectedDate.year;
        final isToday =
            date.day == DateTime.now().day &&
            date.month == DateTime.now().month &&
            date.year == DateTime.now().year;
        return GestureDetector(
          onTap: () => _handleDateTap(date),
          child: Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isToday
                    ? const Color.fromARGB(255, 106, 176, 144)
                    : cs.primary,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isSelected ? cs.onPrimary : cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  Formatters.weekdayAbbr(date),
                  style: TextStyle(
                    color: isSelected ? cs.onPrimary : cs.outline,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusSection(
    String title,
    List<Tarefa> tarefas,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.all(14),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 11),
          if (tarefas.isEmpty)
            Text(
              'Nenhuma tarefa ${title.toLowerCase()}.',
              style: TextStyle(color: color.withValues(alpha: 0.65)),
            ),
          ...tarefas.map(
            (t) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: double.infinity,
              child: TarefaCard(tarefa: t),
            ),
          ),
        ],
      ),
    );
  }
}
