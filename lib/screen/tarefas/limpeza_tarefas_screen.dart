import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:propertask/screen/tarefas/tarefa_detalhe_screen.dart';
import 'package:propertask/widgets/app_drawer.dart';

class LimpezaTarefasScreen extends StatefulWidget {
  final String usuarioId;
  const LimpezaTarefasScreen({required this.usuarioId, super.key});

  @override
  State<LimpezaTarefasScreen> createState() => _LimpezaTarefasScreenState();
}

class _LimpezaTarefasScreenState extends State<LimpezaTarefasScreen> {
  DateTime _selectedDate = DateTime.now();

  List<DateTime> getFiveDayWindow(DateTime center) =>
      List.generate(5, (i) => center.subtract(Duration(days: 2 - i)));
  void _handleDateTap(DateTime clickedDate) {
    if (clickedDate.isAtSameMomentAs(_selectedDate)) return;
    setState(() => _selectedDate = clickedDate);
  }

  DateTime get _inicioDia =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
  DateTime get _fimDiaExclusive => _inicioDia.add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Tarefas"),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/tarefas'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 18),
            child: _buildCalendar(cs),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('propertask')
                  .doc('tarefas')
                  .collection('tarefas')
                  .where(
                    'data',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(_inicioDia),
                  )
                  .where(
                    'data',
                    isLessThan: Timestamp.fromDate(_fimDiaExclusive),
                  )
                  .where('responsavelId', isEqualTo: widget.usuarioId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma tarefa atribuída para este dia.',
                      style: TextStyle(color: cs.outline),
                    ),
                  );
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return LimpezaTarefaCardNovo(
                      data: data,
                      tarefaId: docs[i].id,
                    );
                  },
                );
              },
            ),
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
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 11),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isToday ? Colors.amber : cs.primary,
                width: isSelected ? 2.4 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cs.primary.withAlpha(40),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : [],
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
                  DateFormat.E('pt_BR').format(date),
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
}

class LimpezaTarefaCardNovo extends StatelessWidget {
  final Map<String, dynamic> data;
  final String tarefaId;
  const LimpezaTarefaCardNovo({
    required this.data,
    required this.tarefaId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tipo = data['tipo'] ?? 'limpeza';
    final prop = data['propriedadeNome'] ?? 'Propriedade';
    final status = data['status'] ?? 'pendente';
    final primeiraLinha = '$prop - ${formatTipo(tipo)}';
    final statusVisivel = formatStatusCustom(status);
    final dataFmt = (data['data'] as Timestamp?)?.toDate();
    final dataStr = dataFmt != null ? DateFormat('dd/MM').format(dataFmt) : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 16,
        ),
        leading: CircleAvatar(
          backgroundColor: getTipoColor(tipo, cs),
          child: getTipoIcon(tipo, color: Colors.white),
        ),
        title: Text(
          primeiraLinha,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: Row(
            children: [
              Chip(
                label: Text(
                  statusVisivel,
                  style: TextStyle(
                    color: getStatusColor(status, cs),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: cs.surfaceContainerHighest,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        trailing: Text(
          dataStr,
          style: TextStyle(color: cs.outline, fontWeight: FontWeight.w500),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TarefaDetalheScreen(tarefaId: tarefaId),
          ),
        ),
      ),
    );
  }
}

// -- Helpers globais --
String formatTipo(String tipo) {
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

String formatStatusCustom(String? status) {
  switch (status) {
    case 'pendente':
      return 'Aguardando início';
    case 'em_andamento':
      return 'Iniciada';
    case 'concluida':
      return 'Concluída';
    case 'reaberta':
      return 'Reaberta';
    default:
      return status ?? '';
  }
}

Color getTipoColor(String tipo, ColorScheme cs) {
  switch (tipo) {
    case 'limpeza':
      return cs.primary;
    case 'entrega':
      return cs.secondary;
    case 'recolha':
      return cs.primaryContainer;
    case 'manutencao':
      return cs.secondaryContainer;
    default:
      return cs.outline;
  }
}

Color getStatusColor(String status, ColorScheme cs) {
  switch (status) {
    case 'concluida':
      return Colors.green;
    case 'em_andamento':
      return Colors.orange;
    case 'reaberta':
      return Colors.red;
    case 'pendente':
      return cs.primary;
    default:
      return cs.outline;
  }
}

Icon getTipoIcon(String tipo, {Color color = Colors.black}) {
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
