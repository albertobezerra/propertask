import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
  late String status, tipo, prop, obs, respName, dataStr;
  late bool isGestor, isAtribuido, isLimpeza;
  String? cargo;
  Set<String> selectedShareUrls = {};
  DateTime? inicioEm, concluidaEm;
  String? inicioGeo, concluidaGeo;

  @override
  void initState() {
    super.initState();
    // Update em tempo real
    FirebaseFirestore.instance
        .collection('propertask')
        .doc('tarefas')
        .collection('tarefas')
        .doc(widget.tarefaId)
        .snapshots()
        .listen((snap) {
          if (!mounted || !snap.exists) return;
          final d = snap.data()!;
          setState(() {
            data = d;
            status = data['status'] ?? '';
            tipo = data['tipo'] ?? '';
            obs = data['observacoes'] ?? '';
            prop = data['propriedadeNome'] ?? '';
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
        });
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
    // fallback extra de segurança para alguns devices/plugins
    if (result is String) return File(result);
    throw Exception(
      'compressAndGetFile returned unexpected type: ${result.runtimeType}',
    );
  }

  Future<void> _adicionarImagem(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (!mounted || img == null) return;
    setState(() => loading = true);
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
    setState(() => loading = false);
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
              _adicionarImagem(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Selecionar da galeria'),
            onTap: () {
              Navigator.pop(context);
              _adicionarImagem(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  void _mostrarImagemFull(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(child: Image.network(url)),
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
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final podeIniciar = isAtribuido && status == 'pendente';
    final podeConcluir =
        isAtribuido && status == 'em_andamento' && taskPhotos.isNotEmpty;
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
          Row(
            children: [
              _StatusChip(status: status),
              const SizedBox(width: 10),
              if (_duracaoTarefa != null)
                Text(
                  'Tempo: ${_formatDuration(_duracaoTarefa!)}',
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

          // Mostra imagens e botão SÓ após iniciar a tarefa
          if (status == 'em_andamento' ||
              status == 'concluida' ||
              status == 'reaberta') ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Imagens já enviadas
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
                  // Botão para adicionar imagem (câmera/galeria)
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
          // Botões de ações
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
  }
}

// --- Chips de status modernos ---
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

// --- Utils ---
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
