import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:propertask/widgets/app_drawer.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  DateTimeRange? _dateRange;
  List<Map<String, dynamic>> _tarefasConcluidas = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
    _loadRelatorio();
  }

  Future<void> _loadRelatorio() async {
    if (_dateRange == null) return;
    setState(() => _loading = true);

    final inicioDia = DateTime(
      _dateRange!.start.year,
      _dateRange!.start.month,
      _dateRange!.start.day,
    );
    final fimDiaExclusivo = DateTime(
      _dateRange!.end.year,
      _dateRange!.end.month,
      _dateRange!.end.day,
    ).add(const Duration(days: 1));

    final inicio = Timestamp.fromDate(inicioDia);
    final fim = Timestamp.fromDate(fimDiaExclusivo);

    try {
      final tarefasRef = FirebaseFirestore.instance
          .collection('propertask')
          .doc('tarefas')
          .collection('tarefas');
      final query = tarefasRef
          .where('status', isEqualTo: 'concluida')
          .where('concluidaEm', isGreaterThanOrEqualTo: inicio)
          .where('concluidaEm', isLessThan: fim)
          .orderBy('concluidaEm');
      final snapshot = await query.get();

      if (!mounted) return;
      if (snapshot.docs.isEmpty) {
        setState(() {
          _tarefasConcluidas = [];
          _loading = false;
        });
        return;
      }

      final propIds = snapshot.docs
          .map((d) => (d.data()['propriedadeId'] as String?))
          .whereType<String>()
          .toSet();
      final userIds = snapshot.docs
          .map((d) => (d.data()['responsavelId'] as String?))
          .whereType<String>()
          .toSet();

      final propFutures = {
        for (final id in propIds)
          id: FirebaseFirestore.instance
              .collection('propertask')
              .doc('propriedades')
              .collection('propriedades')
              .doc(id)
              .get(),
      };
      final userFutures = {
        for (final id in userIds)
          id: FirebaseFirestore.instance
              .collection('propertask')
              .doc('usuarios')
              .collection('usuarios')
              .doc(id)
              .get(),
      };

      final propDocs = await Future.wait(propFutures.values);
      final userDocs = await Future.wait(userFutures.values);

      final propMap = <String, Map<String, dynamic>>{
        for (final doc in propDocs) doc.id: doc.data() ?? const {},
      };
      final userMap = <String, Map<String, dynamic>>{
        for (final doc in userDocs) doc.id: doc.data() ?? const {},
      };

      final tarefas = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final pid = data['propriedadeId'] as String?;
        final uid = data['responsavelId'] as String?;
        final prop = pid != null ? (propMap[pid] ?? const {}) : const {};
        final user = uid != null ? (userMap[uid] ?? const {}) : const {};

        final titulo = (data['titulo'] ?? '').toString();
        final tipo = (data['tipo'] ?? '').toString();
        final concluidaEm = (data['concluidaEm'] is Timestamp)
            ? (data['concluidaEm'] as Timestamp).toDate()
            : (data['concluidaEm'] is DateTime
                  ? data['concluidaEm'] as DateTime
                  : null);

        tarefas.add({
          'titulo': titulo,
          'tipo': tipo,
          'propriedade':
              (prop['nome'] ?? data['propriedadeNome'] ?? 'Desconhecida')
                  .toString(),
          'funcionario': (user['nome'] ?? 'Desconhecido').toString(),
          'data': concluidaEm ?? DateTime.fromMillisecondsSinceEpoch(0),
        });
      }

      setState(() {
        _tarefasConcluidas = tarefas;
        _loading = false;
      });
    } on FirebaseException catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? e.code),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cargo = Provider.of<AppState>(context).usuario?.cargo ?? 'LIMPEZA';
    final podeVer = Permissions.podeGerenciarUsuarios(cargo);

    if (!podeVer) {
      return Scaffold(
        appBar: _mainAppBar(context, 'Relatórios', '/relatorios'),
        drawer: const AppDrawer(currentRoute: '/relatorios'),
        body: const Center(
          child: Text('Acesso restrito a supervisores e superiores.'),
        ),
      );
    }

    final porTipo = <String, int>{};
    for (final t in _tarefasConcluidas) {
      final tipo = (t['tipo'] ?? '').toString();
      porTipo[tipo] = (porTipo[tipo] ?? 0) + 1;
    }

    return Scaffold(
      appBar: _mainAppBar(
        context,
        'Relatórios',
        '/relatorios',
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (picked != null) {
                setState(() => _dateRange = picked);
                _loadRelatorio();
              }
            },
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: _exportCSV),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/relatorios'),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Período: ${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_loading)
                    const CircularProgressIndicator()
                  else
                    Text(
                      '${_tarefasConcluidas.length} tarefas concluídas',
                      style: const TextStyle(fontSize: 18),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    children: porTipo.entries.map((e) {
                      final tipo = e.key.isEmpty ? '—' : e.key.toUpperCase();
                      return Chip(
                        label: Text('$tipo: ${e.value}'),
                        backgroundColor: _getTipoColor(e.key),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tarefasConcluidas.isEmpty
                ? const Center(
                    child: Text('Nenhuma tarefa concluída no período.'),
                  )
                : ListView.builder(
                    itemCount: _tarefasConcluidas.length,
                    itemBuilder: (context, i) {
                      final t = _tarefasConcluidas[i];
                      final tipo = (t['tipo'] ?? '').toString();
                      final titulo = (t['titulo'] ?? '').toString();
                      final propriedade = (t['propriedade'] ?? '').toString();
                      final funcionario = (t['funcionario'] ?? '').toString();
                      final data = t['data'] as DateTime;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getTipoColor(tipo),
                            child: Text(
                              tipo.isNotEmpty ? tipo[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            titulo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('$propriedade • $funcionario'),
                          trailing: Text(
                            DateFormat('dd/MM HH:mm').format(data),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  AppBar _mainAppBar(
    BuildContext context,
    String titulo,
    String rota, {
    List<Widget>? actions,
  }) {
    return AppBar(
      title: Text(titulo),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: actions,
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'limpeza':
        return Colors.blue;
      case 'entrega':
        return Colors.green;
      case 'recolha':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _exportCSV() async {
    if (_tarefasConcluidas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum dado para exportar')),
      );
      return;
    }
    final headers = [
      'Título',
      'Tipo',
      'Propriedade',
      'Funcionário',
      'Data/Hora',
    ];
    final rows = _tarefasConcluidas.map((t) {
      final dt = t['data'] as DateTime;
      return [
        (t['titulo'] ?? '').toString(),
        (t['tipo'] ?? '').toString().toUpperCase(),
        (t['propriedade'] ?? '').toString(),
        (t['funcionario'] ?? '').toString(),
        DateFormat('dd/MM/yyyy HH:mm').format(dt),
      ].join(',');
    }).toList();
    final csv = [headers.join(','), ...rows].join('\n');
    final bytes = utf8.encode(csv);

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Relatório de Tarefas Concluídas',
        subject: 'Relatório Propertask',
      ),
    );
  }
}
