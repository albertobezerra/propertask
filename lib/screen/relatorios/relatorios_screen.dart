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
import 'package:propertask/widgets/app_drawer.dart'; // IMPORT DO DRAWER

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  DateTimeRange? _dateRange;
  List<Map<String, dynamic>> _tarefasConcluidas = [];

  @override
  void initState() {
    super.initState();
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    _loadRelatorio();
  }

  Future<void> _loadRelatorio() async {
    if (_dateRange == null) return;

    final inicio = Timestamp.fromDate(_dateRange!.start);
    final fim = Timestamp.fromDate(
      _dateRange!.end.add(const Duration(days: 1)),
    );

    final snapshot = await FirebaseFirestore.instance
        .collection('propertask')
        .doc('tarefas')
        .collection('tarefas')
        .where('status', isEqualTo: 'concluida')
        .where('concluidaEm', isGreaterThanOrEqualTo: inicio)
        .where('concluidaEm', isLessThan: fim)
        .get();

    final tarefas = <Map<String, dynamic>>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final propDoc = await FirebaseFirestore.instance
          .collection('propertask')
          .doc('propriedades')
          .collection('propriedades')
          .doc(data['propriedadeId'])
          .get();
      final userDoc = await FirebaseFirestore.instance
          .collection('propertask')
          .doc('usuarios')
          .collection('usuarios')
          .doc(data['responsavelId'])
          .get();

      tarefas.add({
        'titulo': data['titulo'],
        'tipo': data['tipo'],
        'propriedade': propDoc['nome'] ?? 'Desconhecida',
        'funcionario': userDoc['nome'] ?? 'Desconhecido',
        'data': (data['concluidaEm'] as Timestamp).toDate(),
      });
    }

    if (!mounted) return;
    setState(() => _tarefasConcluidas = tarefas);
  }

  @override
  Widget build(BuildContext context) {
    final cargo = Provider.of<AppState>(context).usuario?.cargo ?? 'LIMPEZA';
    final podeVer = Permissions.podeGerenciarUsuarios(cargo);

    if (!podeVer) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Relatórios'),
          backgroundColor: Colors.blue.shade700, // PADRÃO VISUAL
          foregroundColor: Colors.white,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            ),
          ), // LEADING QUE ABRE O DRAWER
        ),
        drawer: const AppDrawer(currentRoute: '/relatorios'), // DRAWER PADRÃO
        body: const Center(
          child: Text('Acesso restrito a supervisores e superiores.'),
        ),
      );
    }

    final porTipo = <String, int>{};
    for (final t in _tarefasConcluidas) {
      porTipo[t['tipo']] = (porTipo[t['tipo']] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: Colors.blue.shade700, // PADRÃO VISUAL
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ), // LEADING QUE ABRE O DRAWER
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
              if (!mounted) return;
              if (picked != null) {
                setState(() => _dateRange = picked);
                _loadRelatorio();
              }
            },
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: _exportCSV),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/relatorios'), // DRAWER PADRÃO
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
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
                  const SizedBox(height: 12),
                  Text(
                    '${_tarefasConcluidas.length} tarefas concluídas',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: porTipo.entries.map((e) {
                      return Chip(
                        label: Text('${e.key.toUpperCase()}: ${e.value}'),
                        backgroundColor: _getTipoColor(e.key),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _tarefasConcluidas.isEmpty
                ? const Center(
                    child: Text('Nenhuma tarefa concluída no período.'),
                  )
                : ListView.builder(
                    itemCount: _tarefasConcluidas.length,
                    itemBuilder: (context, i) {
                      final t = _tarefasConcluidas[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getTipoColor(t['tipo']),
                            child: Text(
                              t['tipo'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            t['titulo'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${t['propriedade']} • ${t['funcionario']}',
                          ),
                          trailing: Text(
                            DateFormat('dd/MM HH:mm').format(t['data']),
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

  Color _getTipoColor(String tipo) {
    switch (tipo) {
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
      return [
        t['titulo'],
        t['tipo'].toUpperCase(),
        t['propriedade'],
        t['funcionario'],
        DateFormat('dd/MM/yyyy HH:mm').format(t['data']),
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
