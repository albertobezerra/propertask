import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';

class TarefaDetalheScreen extends StatefulWidget {
  final String tarefaId;
  const TarefaDetalheScreen({super.key, required this.tarefaId});

  @override
  State<TarefaDetalheScreen> createState() => _TarefaDetalheScreenState();
}

class _TarefaDetalheScreenState extends State<TarefaDetalheScreen> {
  Map<String, dynamic> data = {};
  bool loading = true;

  List<String> taskPhotos = [];
  List<File> localTaskPhotos = [];

  late String status, tipo, prop, obs, respName, dataStr, propId;
  late bool isGestor, isAtribuido, isLimpeza;
  String? cargo;
  DateTime? inicioEm, concluidaEm;
  String? inicioGeo, concluidaGeo;

  Map<String, dynamic>? propriedadeData;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('propertask')
        .doc('tarefas')
        .collection('tarefas')
        .doc(widget.tarefaId)
        .snapshots()
        .listen((snap) async {
          if (!mounted || !snap.exists) return;
          final d = snap.data()!;
          setState(() {
            data = d;
            status = data['status'] ?? '';
            tipo = data['tipo'] ?? '';
            obs = data['observacoes'] ?? '';
            prop = data['propriedadeNome'] ?? '';
            propId = data['propriedadeId'] ?? '';
            respName = data['responsavelNome'] ?? '—';
            taskPhotos = List<String>.from(data['fotos'] ?? []);
            final usuario = Provider.of<AppState>(
              context,
              listen: false,
            ).usuario!;
            cargo = usuario.cargo;
            isLimpeza = Permissions.cargoFromString(cargo!) == Cargo.limpeza;
            isGestor =
                Permissions.cargoFromString(cargo!) == Cargo.dev ||
                Permissions.cargoFromString(cargo!) == Cargo.coordenador ||
                Permissions.cargoFromString(cargo!) == Cargo.ceo ||
                Permissions.cargoFromString(cargo!) == Cargo.supervisor;
            isAtribuido = (data['responsavelId'] ?? '') == usuario.id;
            dataStr = data['data'] != null && data['data'] is Timestamp
                ? DateFormat(
                    'dd/MM/yyyy',
                  ).format((data['data'] as Timestamp).toDate())
                : '';
            inicioEm = data['inicioEm'] != null && data['inicioEm'] is Timestamp
                ? (data['inicioEm'] as Timestamp).toDate()
                : null;
            concluidaEm =
                data['concluidaEm'] != null && data['concluidaEm'] is Timestamp
                ? (data['concluidaEm'] as Timestamp).toDate()
                : null;
            inicioGeo = data['inicioGeo'] as String?;
            concluidaGeo = data['concluidaGeo'] as String?;
            loading = false;
          });
          if (d['propriedadeId'] != null) {
            _loadPropriedade(d['propriedadeId']);
          }
        });
  }

  Future<void> _loadPropriedade(String propId) async {
    final doc = await FirebaseFirestore.instance
        .collection('propertask')
        .doc('propriedades')
        .collection('propriedades')
        .doc(propId)
        .get();
    if (doc.exists) {
      setState(() {
        propriedadeData = doc.data();
      });
    }
  }

  Future<void> _getLocationAndTime(String fieldTime, String fieldGeo) async {
    try {
      final location = Location();
      final locData = await location.getLocation();
      final geo =
          '${locData.latitude?.toStringAsFixed(5)},${locData.longitude?.toStringAsFixed(5)}';
      await FirebaseFirestore.instance
          .collection('propertask')
          .doc('tarefas')
          .collection('tarefas')
          .doc(widget.tarefaId)
          .update({fieldTime: FieldValue.serverTimestamp(), fieldGeo: geo});
    } catch (_) {}
  }

  Future<File> _compressImage(File file) async {
    final target = file.path.replaceAll('.jpg', '_min.jpg');
    final dynamic result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      target,
      quality: 70,
      minWidth: 1200,
      minHeight: 1200,
      format: CompressFormat.jpeg,
    );
    if (result == null) return file;
    if (result is File) return result;
    if (result is XFile) return File(result.path);
    if (result is String) return File(result);
    throw Exception(
      'compressAndGetFile returned unexpected type: ${result.runtimeType}',
    );
  }

  Future<void> _adicionarImagens() async {
    final picker = ImagePicker();
    final List<XFile> imagens = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (!mounted || imagens.isEmpty) return;
    setState(() {
      localTaskPhotos.addAll(imagens.map((img) => File(img.path)));
    });
    for (final img in imagens) {
      final file = await _compressImage(File(img.path));
      final fileName =
          '${widget.tarefaId}_${DateTime.now().millisecondsSinceEpoch}_${img.name}';
      final ref = FirebaseStorage.instance.ref().child('tarefas/$fileName');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      final updatedList = [...(data['fotos'] ?? []), url];
      await FirebaseFirestore.instance
          .collection('propertask')
          .doc('tarefas')
          .collection('tarefas')
          .doc(widget.tarefaId)
          .update({'fotos': updatedList});
      if (!mounted) return;
      setState(() {
        taskPhotos.add(url);
        localTaskPhotos.removeWhere((f) => f.path == img.path);
      });
    }
  }

  Future<void> _adicionarImagemCamera() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (!mounted || img == null) return;
    setState(() {
      localTaskPhotos.add(File(img.path));
    });
    final file = await _compressImage(File(img.path));
    final fileName =
        '${widget.tarefaId}_${DateTime.now().millisecondsSinceEpoch}_${img.name}';
    final ref = FirebaseStorage.instance.ref().child('tarefas/$fileName');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    final updatedList = [...(data['fotos'] ?? []), url];
    await FirebaseFirestore.instance
        .collection('propertask')
        .doc('tarefas')
        .collection('tarefas')
        .doc(widget.tarefaId)
        .update({'fotos': updatedList});
    if (!mounted) return;
    setState(() {
      taskPhotos.add(url);
      localTaskPhotos.removeWhere((f) => f.path == img.path);
    });
  }

  void _escolherTipoImagem(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tirar foto'),
            onTap: () {
              Navigator.pop(context);
              _adicionarImagemCamera();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Selecionar da galeria'),
            onTap: () {
              Navigator.pop(context);
              _adicionarImagens();
            },
          ),
        ],
      ),
    );
  }

  void _mostrarImagemFull(String urlOrPath, {bool local = false}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: local
                  ? Image.file(File(urlOrPath))
                  : Image.network(urlOrPath),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Duration? get _duracaoTarefa {
    if (inicioEm != null && concluidaEm != null) {
      return concluidaEm!.difference(inicioEm!);
    }
    if (inicioEm != null &&
        (status == 'em_andamento' || status == 'reaberta')) {
      return DateTime.now().difference(inicioEm!);
    }
    return null;
  }

  Future<void> _abrirEscolhaMapa(
    BuildContext context,
    String enderecoLimpo,
  ) async {
    try {
      final available = await MapLauncher.installedMaps;
      if (available.isEmpty) {
        final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(enderecoLimpo)}',
        );
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
      if (!context.mounted) return;
      await showModalBottomSheet(
        context: context,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          return SafeArea(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: available.length,
              separatorBuilder: (context, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final m = available[i];
                return ListTile(
                  leading: const Icon(Icons.map, size: 24),
                  title: Text(m.mapName),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await m.showMarker(
                        coords: Coords(0, 0),
                        title: enderecoLimpo,
                        description: '',
                        extraParams: {'q': enderecoLimpo},
                      );
                    } catch (_) {
                      final url = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(enderecoLimpo)}',
                      );
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final podeIniciar = isAtribuido && status == 'pendente';
    final podeConcluir =
        isAtribuido &&
        (status == 'em_andamento' || status == 'reaberta') &&
        taskPhotos.isNotEmpty;
    final podeReabrir = isGestor && status == 'concluida';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            getTipoIcon(tipo, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$prop - ${_formatTipo(tipo)}',
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (propriedadeData != null) ...[
            _addressCard(
              context,
              propriedadeData!['endereco'] ?? '',
              () => _abrirEscolhaMapa(
                context,
                propriedadeData!['endereco'] ??
                    propriedadeData!['cidade'] ??
                    '',
              ),
            ),
            _sectionCard(
              context,
              icon: Icons.vpn_key,
              title: 'Acessos',
              children: [
                if (propriedadeData!['levarChave'] == true)
                  _tile(icon: Icons.key, title: 'Levar chave', subtitle: 'Sim'),
                if ((propriedadeData!['codigoPredio'] ?? '')
                    .toString()
                    .isNotEmpty)
                  _tile(
                    icon: Icons.domain,
                    title: 'Código do prédio',
                    subtitle: propriedadeData!['codigoPredio'],
                  ),
                if ((propriedadeData!['codigoApartamento'] ?? '')
                    .toString()
                    .isNotEmpty)
                  _tile(
                    icon: Icons.meeting_room,
                    title: 'Código do apartamento',
                    subtitle: propriedadeData!['codigoApartamento'],
                  ),
                if (propriedadeData!['temLockbox'] == true) ...[
                  _tile(
                    icon: Icons.lock_outline,
                    title: 'Lockbox',
                    subtitle: 'Sim',
                  ),
                  if ((propriedadeData!['lockboxCodigo'] ?? '')
                      .toString()
                      .isNotEmpty)
                    _tile(
                      icon: Icons.pin,
                      title: 'Código da lockbox',
                      subtitle: propriedadeData!['lockboxCodigo'],
                    ),
                  if ((propriedadeData!['lockboxLocal'] ?? '')
                      .toString()
                      .isNotEmpty)
                    _tile(
                      icon: Icons.place,
                      title: 'Local da lockbox',
                      subtitle: propriedadeData!['lockboxLocal'],
                    ),
                ],
              ],
            ),
            // Só mostra amenidades e roupas se for limpeza!
            if (tipo == 'limpeza') ...[
              const SizedBox(height: 10),
              _sectionCard(
                context,
                icon: Icons.coffee,
                title: 'Amenidades e fornecimento',
                children: [
                  _tile(
                    icon: Icons.coffee,
                    title: 'Café',
                    subtitle: propriedadeData!['cafe'] ?? 'Sem café',
                  ),
                  if ((propriedadeData!['fornecedorRoupa'] ?? '')
                      .toString()
                      .isNotEmpty)
                    _tile(
                      icon: Icons.local_laundry_service,
                      title: 'Fornecedor de roupa',
                      subtitle: propriedadeData!['fornecedorRoupa'],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_temItensRoupa(propriedadeData!['roupa'] ?? {}))
                _roupaCard(context, propriedadeData!['roupa']),
              const SizedBox(height: 14),
            ],
          ],
          Row(
            children: [
              _StatusChip(status: status),
              const SizedBox(width: 10),
              if (_duracaoTarefa != null &&
                  (status == 'em_andamento' || status == 'reaberta'))
                TimerBuilder.periodic(
                  const Duration(seconds: 1),
                  builder: (_) {
                    final d = DateTime.now().difference(inicioEm!);
                    return Text(
                      'Tempo: ${_formatDuration(d)}',
                      style: TextStyle(
                        color: cs.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              if (_duracaoTarefa != null && status == 'concluida')
                Text(
                  'Durou: ${_formatDuration(_duracaoTarefa!)}',
                  style: TextStyle(
                    color: cs.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 18),
              const SizedBox(width: 6),
              Text(
                respName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Text(dataStr, style: TextStyle(color: cs.outline)),
            ],
          ),
          if (obs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              obs,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
          ],
          if (status == 'em_andamento' ||
              status == 'reaberta' ||
              status == 'concluida') ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...localTaskPhotos.map(
                    (f) => GestureDetector(
                      onTap: () => _mostrarImagemFull(f.path, local: true),
                      child: Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                f,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(80),
                                  shape: BoxShape.circle,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ...taskPhotos.map(
                    (url) => GestureDetector(
                      onTap: () => _mostrarImagemFull(url),
                      child: Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                url,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if ((status == 'em_andamento' ||
                                    status == 'reaberta') &&
                                isAtribuido)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () async => await _deleteImage(url),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(80),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if ((status == 'em_andamento' || status == 'reaberta') &&
                      isAtribuido)
                    GestureDetector(
                      onTap: () => _escolherTipoImagem(context),
                      child: Container(
                        width: 90,
                        height: 90,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: cs.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: cs.primary, width: 1.5),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: cs.primary,
                            size: 35,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 21),
          Row(
            children: [
              if (podeIniciar)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => loading = true);
                      await FirebaseFirestore.instance
                          .collection('propertask')
                          .doc('tarefas')
                          .collection('tarefas')
                          .doc(widget.tarefaId)
                          .update({'status': 'em_andamento'});
                      await _getLocationAndTime('inicioEm', 'inicioGeo');
                      setState(() => loading = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Iniciar tarefa'),
                  ),
                ),
              if (podeConcluir)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => loading = true);
                      await FirebaseFirestore.instance
                          .collection('propertask')
                          .doc('tarefas')
                          .collection('tarefas')
                          .doc(widget.tarefaId)
                          .update({'status': 'concluida'});
                      await _getLocationAndTime('concluidaEm', 'concluidaGeo');
                      setState(() => loading = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Concluir tarefa'),
                  ),
                ),
              if (podeReabrir)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => loading = true);
                      await FirebaseFirestore.instance
                          .collection('propertask')
                          .doc('tarefas')
                          .collection('tarefas')
                          .doc(widget.tarefaId)
                          .update({'status': 'reaberta'});
                      setState(() => loading = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reabrir'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteImage(String url) async {
    final list = List<String>.from(data['fotos'] ?? []);
    list.remove(url);
    await FirebaseFirestore.instance
        .collection('propertask')
        .doc('tarefas')
        .collection('tarefas')
        .doc(widget.tarefaId)
        .update({'fotos': list});
    setState(() {
      taskPhotos.remove(url);
    });
  }
}

// --------- HELPERS/WIDGETS (não mexa, só deixe abaixo da classe principal) ---------
Widget _addressCard(BuildContext context, String endereco, VoidCallback onTap) {
  final cs = Theme.of(context).colorScheme;
  return Card(
    color: cs.surfaceContainerHighest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      onTap: endereco.trim().isEmpty ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Icon(Icons.place, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                endereco.isNotEmpty ? endereco : 'Sem endereço',
                style: const TextStyle(color: Colors.black87),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.map, size: 18, color: cs.primary),
          ],
        ),
      ),
    ),
  );
}

Widget _sectionCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required List<Widget> children,
}) {
  final cs = Theme.of(context).colorScheme;
  return Card(
    color: cs.surfaceContainerHighest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

ListTile _tile({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle.isEmpty ? '—' : subtitle),
  );
}

bool _temItensRoupa(Map<String, dynamic>? roupa) {
  if (roupa == null || roupa.isEmpty) return false;
  for (final v in roupa.values) {
    final qtd = v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
    if (qtd > 0) return true;
  }
  return false;
}

Widget _roupaCard(BuildContext context, Map<String, dynamic> roupa) {
  final cs = Theme.of(context).colorScheme;
  int asIntLocal(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  final mapa = <String, int>{
    'fronha': asIntLocal(roupa['fronha']),
    'lençol_casal': asIntLocal(roupa['lençol_casal'] ?? roupa['lencol_casal']),
    'capa_casal': asIntLocal(roupa['capa_casal']),
    'lençol_solteiro': asIntLocal(
      roupa['lençol_solteiro'] ?? roupa['lencol_solteiro'],
    ),
    'capa_solteiro': asIntLocal(roupa['capa_solteiro']),
    'toalha_banho': asIntLocal(roupa['toalha_banho']),
    'toalha_rosto': asIntLocal(roupa['toalha_rosto']),
    'tapete': asIntLocal(roupa['tapete']),
    'pano_limpeza': asIntLocal(roupa['pano_limpeza']),
  };
  final chips = <Widget>[];
  mapa.forEach((k, qtd) {
    if (qtd > 0) {
      final label = '${qtd}x ${_titleCase(_formatNomeItem(k, qtd))}';
      chips.add(
        Chip(
          label: Text(label),
          visualDensity: VisualDensity.compact,
          backgroundColor: cs.secondaryContainer,
          labelStyle: TextStyle(color: cs.onSecondaryContainer),
          avatar: const Icon(Icons.local_laundry_service, size: 16),
        ),
      );
    }
  });
  return _sectionCard(
    context,
    icon: Icons.local_laundry_service,
    title: 'Roupas e lavanderia',
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        child: Wrap(spacing: 8, runSpacing: -8, children: chips),
      ),
    ],
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (status) {
      case 'em_andamento':
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        break;
      case 'concluida':
        bg = Colors.green.shade50;
        text = Colors.green.shade900;
        break;
      case 'reaberta':
        bg = Colors.red.shade50;
        text = Colors.red.shade800;
        break;
      case 'pendente':
      default:
        bg = Theme.of(context).colorScheme.primary.withAlpha(35);
        text = Theme.of(context).colorScheme.primary;
        break;
    }
    String label =
        {
          'pendente': 'Aguardando início',
          'em_andamento': 'Iniciada',
          'concluida': 'Concluída',
          'reaberta': 'Reaberta',
        }[status] ??
        status;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.w600),
      ),
    );
  }
}

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

String _formatDuration(Duration d) {
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}min';
  return '${d.inMinutes}min';
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

String _formatNomeItem(String key, int qtd) {
  String nome = key
      .replaceAll('_', ' ')
      .replaceAll('lencol', 'lençol')
      .replaceAll('casal', 'de casal')
      .replaceAll('solteiro', 'de solteiro')
      .replaceAll('banho', 'de banho')
      .replaceAll('rosto', 'de rosto')
      .replaceAll('pano limpeza', 'pano de limpeza');
  if (qtd != 1) {
    nome = nome
        .replaceAll('fronha', 'fronhas')
        .replaceAll('lençol', 'lençóis')
        .replaceAll('capa', 'capas')
        .replaceAll('toalha', 'toalhas')
        .replaceAll('tapete', 'tapetes')
        .replaceAll('pano de limpeza', 'panos de limpeza');
  }
  return nome;
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
