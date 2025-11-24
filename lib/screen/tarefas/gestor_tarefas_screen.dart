import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:propertask/screen/tarefas/tarefa_detalhe_screen.dart';
import 'package:propertask/screen/tarefas/tarefa_form_screen.dart';
import 'package:propertask/widgets/app_drawer.dart';

// Widget principal: Tarefas para DEV/COORD/CEO/SUP
class GestorTarefasScreen extends StatefulWidget {
  const GestorTarefasScreen({super.key});

  @override
  State<GestorTarefasScreen> createState() => _GestorTarefasScreenState();
}

class _GestorTarefasScreenState extends State<GestorTarefasScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _status = 'Todos';
  String _tipo = 'Todos';
  DateTime _selectedDate = DateTime.now();

  DateTime get _inicioDia =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
  DateTime get _fimDiaExclusive => _inicioDia.add(const Duration(days: 1));

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tarefas"),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TarefaFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
      body: Column(
        children: [
          // Buscador e calendário
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar tarefa ou propriedade...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              tooltip: 'Limpar',
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Data',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd/MM').format(_selectedDate),
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(
                        value: 'pendente',
                        child: Text('Aguardando início'),
                      ),
                      DropdownMenuItem(
                        value: 'em_andamento',
                        child: Text('Iniciada'),
                      ),
                      DropdownMenuItem(
                        value: 'concluida',
                        child: Text('Concluída'),
                      ),
                      DropdownMenuItem(
                        value: 'reaberta',
                        child: Text('Reaberta'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'Todos'),
                    decoration: InputDecoration(
                      labelText: 'Status',
                      prefixIcon: const Icon(Icons.flag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(
                        value: 'limpeza',
                        child: Text('Limpeza'),
                      ),
                      DropdownMenuItem(
                        value: 'entrega',
                        child: Text('Entrega'),
                      ),
                      DropdownMenuItem(
                        value: 'recolha',
                        child: Text('Recolha'),
                      ),
                      DropdownMenuItem(
                        value: 'manutencao',
                        child: Text('Manutenção'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _tipo = v ?? 'Todos'),
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
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
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma tarefa para este dia.',
                      style: TextStyle(color: cs.outline),
                    ),
                  );
                }

                var docs = snapshot.data!.docs.toList();

                if (_status != 'Todos') {
                  docs = docs
                      .where((d) => (d['status'] ?? 'pendente') == _status)
                      .toList();
                }
                if (_tipo != 'Todos') {
                  docs = docs.where((d) => (d['tipo'] ?? '') == _tipo).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final titulo = (d['titulo'] ?? '').toString().toLowerCase();
                    final prop = (d['propriedadeNome'] ?? '')
                        .toString()
                        .toLowerCase();
                    return titulo.contains(_searchQuery) ||
                        prop.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma tarefa atende aos filtros.',
                      style: TextStyle(color: cs.outline),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return TarefaCardGestor(data: data, tarefaId: docs[i].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TarefaCardGestor extends StatelessWidget {
  final Map<String, dynamic> data;
  final String tarefaId;
  const TarefaCardGestor({
    required this.data,
    required this.tarefaId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tipo = data['tipo'] ?? 'limpeza';
    final status = data['status'] ?? 'pendente';
    final prop = data['propriedadeNome'] ?? '—';
    final respName = data['responsavelNome'] ?? '—';
    final respAvatar =
        data['responsavelAvatar']; // Se salva a url do avatar (opcional)
    final dataFmt = (data['data'] as Timestamp?)?.toDate();
    final dataStr = dataFmt != null ? DateFormat('dd/MM').format(dataFmt) : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 11,
          horizontal: 14,
        ),
        leading: CircleAvatar(
          backgroundColor: _getTipoColor(tipo, cs),
          child: getTipoIcon(tipo, color: Colors.white),
        ),
        title: Text(
          '$prop - ${_formatTipo(tipo)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar pequeno do responsável
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primaryContainer,
              backgroundImage: respAvatar != null
                  ? NetworkImage(respAvatar)
                  : null,
              child: respAvatar == null
                  ? Icon(Icons.person, color: cs.primary)
                  : null,
            ),
            const SizedBox(width: 7),
            Text(respName, style: const TextStyle(fontWeight: FontWeight.w500)),
            // Espaço flex antes do status
            const Spacer(),
            Text(
              _formatStatusCustom(status),
              style: TextStyle(
                color: _getStatusColor(status, cs),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Text(dataStr, style: TextStyle(color: cs.outline)),
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

// ---- Utils (copie para um arquivo só ou mantenha iguais nas suas telas para consistência)
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

String _formatStatusCustom(String? status) {
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

Color _getTipoColor(String tipo, ColorScheme cs) {
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

Color _getStatusColor(String status, ColorScheme cs) {
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
