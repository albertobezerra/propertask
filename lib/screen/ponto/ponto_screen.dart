import 'package:flutter/material.dart';
import 'package:propertask/screen/ponto/ponto_historico_screen.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:propertask/widgets/app_drawer.dart';

class PontoScreen extends StatefulWidget {
  const PontoScreen({super.key});

  @override
  State<PontoScreen> createState() => _PontoScreenState();
}

class _PontoScreenState extends State<PontoScreen> {
  String? _ultimoPonto;
  String _status = 'Carregando...';
  Position? _position;

  @override
  void initState() {
    super.initState();
    _checkPermissoes();
  }

  Future<void> _checkPermissoes() async {
    final cargo =
        Provider.of<AppState>(context, listen: false).usuario?.cargo ??
        'LIMPEZA';
    final podeBater = ['LIMPEZA', 'LAVANDERIA', 'MOTORISTA'].contains(cargo);

    if (!podeBater) {
      if (!mounted) return;
      setState(() => _status = 'Você não precisa bater ponto.');
      return;
    }

    final permitted = await Geolocator.isLocationServiceEnabled();
    if (!permitted) {
      if (!mounted) return;
      setState(() => _status = 'GPS desativado.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() => _status = 'Permissão de GPS negada.');
      return;
    }

    _position = await Geolocator.getCurrentPosition();
    await _carregarUltimoPonto();
  }

  Future<void> _carregarUltimoPonto() async {
    final empresaId = Provider.of<AppState>(context, listen: false).empresaId!;
    final userId = Provider.of<AppState>(context, listen: false).user!.uid;
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month, hoje.day);
    final fim = inicio.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('empresas')
        .doc(empresaId)
        .collection('pontoRegistros')
        .where('usuarioId', isEqualTo: userId)
        .where(
          'horarioReal',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .where('horarioReal', isLessThan: Timestamp.fromDate(fim))
        .orderBy('horarioReal', descending: true)
        .limit(1)
        .get();

    if (!mounted) return;

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final tipo = data['tipo'] as String;
      final horario = (data['horarioReal'] as Timestamp).toDate();
      setState(() {
        _ultimoPonto = tipo;
        _status = 'Último: $tipo às ${DateFormat('HH:mm').format(horario)}';
      });
    } else {
      setState(() => _status = 'Nenhum ponto hoje.');
    }
  }

  Future<void> _baterPonto(String tipo) async {
    if (_position == null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('GPS não disponível')),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userId = Provider.of<AppState>(context, listen: false).user!.uid;
    final empresaId = Provider.of<AppState>(context, listen: false).empresaId!;
    final agora = DateTime.now();
    final arredondado = _arredondarHora(agora);

    try {
      await FirebaseFirestore.instance
          .collection('empresas')
          .doc(empresaId)
          .collection('pontoRegistros')
          .add({
            'usuarioId': userId,
            'tipo': tipo,
            'horarioReal': Timestamp.fromDate(agora),
            'horarioArredondado': Timestamp.fromDate(arredondado),
            'localizacao': GeoPoint(_position!.latitude, _position!.longitude),
            'observacao': null,
          });

      if (!mounted) return;

      setState(() {
        _ultimoPonto = tipo;
        _status = '$tipo batido às ${DateFormat('HH:mm').format(agora)}';
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('$tipo registrado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar ponto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DateTime _arredondarHora(DateTime hora) {
    final minutos = hora.minute;
    final arredondado = minutos < 15
        ? 0
        : minutos < 45
        ? 30
        : 60;
    final novaHora = hora.copyWith(
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    if (arredondado == 60) {
      return novaHora.add(const Duration(hours: 1));
    }
    return novaHora.add(Duration(minutes: arredondado));
  }

  @override
  Widget build(BuildContext context) {
    final cargo = Provider.of<AppState>(context).usuario?.cargo ?? 'LIMPEZA';
    final podeBater = ['LIMPEZA', 'LAVANDERIA', 'MOTORISTA'].contains(cargo);
    final podeVerHistorico = Permissions.podeGerenciarUsuarios(cargo);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ponto'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (podeVerHistorico)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PontoHistoricoScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/ponto'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Card(
            color: cs.surfaceContainerHighest,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 80,
                    color: podeBater ? cs.primary : cs.outline,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Registro de Ponto",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const Divider(height: 28, thickness: 1.2),
                  Text(
                    _status,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (podeBater) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _ultimoPonto == 'entrada'
                              ? null
                              : () => _baterPonto('entrada'),
                          icon: const Icon(Icons.login),
                          label: const Text('ENTRADA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 23,
                              vertical: 15,
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        ElevatedButton.icon(
                          onPressed: _ultimoPonto == 'saida'
                              ? null
                              : () => _baterPonto('saida'),
                          icon: const Icon(Icons.logout),
                          label: const Text('SAÍDA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 23,
                              vertical: 15,
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Você não precisa bater ponto.',
                      style: TextStyle(color: cs.outline),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
