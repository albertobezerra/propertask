import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';
import 'package:propertask/screen/tarefas/tarefa_detalhe_screen.dart';
import 'package:propertask/screen/tarefas/tarefa_form_screen.dart';
import 'package:propertask/widgets/app_drawer.dart';

class TarefasScreen extends StatelessWidget {
  const TarefasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = Provider.of<AppState>(context).usuario;
    final cargoEnum = usuario != null
        ? Permissions.cargoFromString(usuario.cargo)
        : Cargo.limpeza;
    if (cargoEnum == Cargo.limpeza || cargoEnum == Cargo.lavanderia) {
      return const LimpezaTarefasScreen();
    }
    return const GestorTarefasScreen();
  }
}

// =========== LIMPEZA (Só suas tarefas, apenas calendário, sem FAB) =============

class LimpezaTarefasScreen extends StatefulWidget {
  const LimpezaTarefasScreen({super.key});
  @override
  State<LimpezaTarefasScreen> createState() => _LimpezaTarefasScreenState();
}

class _LimpezaTarefasScreenState extends State<LimpezaTarefasScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime get _inicioDia =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
  DateTime get _fimDiaExclusive => _inicioDia.add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final usuario = Provider.of<AppState>(context, listen: false).usuario!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tarefas do Dia"),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      drawer: const AppDrawer(currentRoute: '/tarefas'),
      body: Column(
        children: [
          // Calendário
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Text(
                  'Selecione a data:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(DateFormat('dd/MM').format(_selectedDate)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          // Lista de tarefas
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
                  .where('responsavelId', isEqualTo: usuario.id)
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
                    return TarefaCardClean(
                      data: data,
                      tarefaId: docs[i].id,
                      isLimpeza: true,
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
}

// =========== GESTORES (SUP, DEV, COORD, CEO) =============

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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tarefas"),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      drawer: const AppDrawer(currentRoute: '/tarefas'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TarefaFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
      body: Column(
        children: [
          // BUSCA + CALENDÁRIO
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
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('dd/MM').format(_selectedDate)),
                    onPressed: () async {
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
                  ),
                ),
              ],
            ),
          ),
          // STATUS + TIPO
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
                        child: Text('Pendente'),
                      ),
                      DropdownMenuItem(
                        value: 'em_andamento',
                        child: Text('Em andamento'),
                      ),
                      DropdownMenuItem(
                        value: 'concluida',
                        child: Text('Concluída'),
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
          // LISTA
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

                // Filtros
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
                    return TarefaCardClean(
                      data: data,
                      tarefaId: docs[i].id,
                      isLimpeza: false,
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
}

// =================== TarefaCardClean universal ====================

class TarefaCardClean extends StatelessWidget {
  final Map<String, dynamic> data;
  final String tarefaId;
  final bool isLimpeza;

  const TarefaCardClean({
    required this.data,
    required this.tarefaId,
    required this.isLimpeza,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tipo = data['tipo'] ?? 'limpeza';
    final status = data['status'] ?? 'pendente';
    final prop = data['propriedadeNome'] ?? '—';
    final respName = data['responsavelNome'] ?? '—';
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
        title: Row(
          children: [
            Text(prop, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 9),
            Text(
              dataStr,
              style: TextStyle(color: cs.outline, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatStatus(status),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _getStatusColor(status, cs),
              ),
            ),
            if (!isLimpeza)
              Text(
                'Responsável: $respName',
                style: TextStyle(fontSize: 13, color: cs.outline),
              ),
          ],
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

// Utilitários (idênticos do bloco anterior)
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
    case 'pendente':
      return cs.primary;
    default:
      return cs.outline;
  }
}

String _formatStatus(String? status) {
  switch (status) {
    case 'pendente':
      return 'Pendente';
    case 'em_andamento':
      return 'Em andamento';
    case 'concluida':
      return 'Concluída';
    default:
      return status ?? '';
  }
}
