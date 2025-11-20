import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';

class TarefaDetalheScreen extends StatefulWidget {
  final String tarefaId;
  const TarefaDetalheScreen({super.key, required this.tarefaId});

  @override
  State<TarefaDetalheScreen> createState() => _TarefaDetalheScreenState();
}

class _TarefaDetalheScreenState extends State<TarefaDetalheScreen> {
  late Map<String, dynamic> data;
  bool loading = true;

  List<String> taskPhotos = [];
  List<String> lockboxPhotos = [];
  late bool isLockbox;
  late String status, tipo, prop, dataStr, respName, obs;
  late bool isGestor, isAtribuido, isLimpeza;
  String? cargo;
  Set<String> selectedShareUrls = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final snap = await FirebaseFirestore.instance
        .collection('propertask')
        .doc('tarefas')
        .collection('tarefas')
        .doc(widget.tarefaId)
        .get();
    if (!mounted) return;
    data = snap.data() as Map<String, dynamic>;
    status = data['status'] ?? '';
    tipo = data['tipo'] ?? '';
    obs = data['observacoes'] ?? '';
    prop = data['propriedadeNome'] ?? '';
    respName = data['responsavelNome'] ?? '—';
    final dt = (data['data'] as Timestamp?)?.toDate();
    dataStr = dt != null ? DateFormat('dd/MM/yyyy').format(dt) : '';
    isLockbox = (tipo == 'limpeza' && (data['lockbox'] ?? false) == true);
    taskPhotos = List<String>.from(data['fotos'] ?? []);
    lockboxPhotos = List<String>.from(data['lockboxFotos'] ?? []);
    final usuario = Provider.of<AppState>(context, listen: false).usuario!;
    cargo = usuario.cargo;
    isLimpeza = Permissions.cargoFromString(cargo!) == Cargo.limpeza;
    isGestor = !isLimpeza;
    isAtribuido = (data['responsavelId'] ?? '') == usuario.id;
    if (!mounted) return;
    setState(() {
      loading = false;
      selectedShareUrls = {};
    });
  }

  // Múltiplo: image_picker não suporta nativamente multi, então chame várias vezes ou use outro pacote.
  Future<void> _uploadMultipleImages({bool forLockbox = false}) async {
    final picker = ImagePicker();
    final List<XFile> imgs = await picker.pickMultiImage();
    if (!mounted || imgs.isEmpty) return;
    setState(() => loading = true);
    final urls = <String>[];
    for (final img in imgs) {
      final fileName =
          '${widget.tarefaId}_${DateTime.now().millisecondsSinceEpoch}_${img.name}${forLockbox ? "_lockbox" : ""}';
      final ref = FirebaseStorage.instance.ref().child('tarefas/$fileName');
      await ref.putFile(File(img.path));
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    final key = forLockbox ? 'lockboxFotos' : 'fotos';
    final updatedList = [...(data[key] ?? []), ...urls];
    await FirebaseFirestore.instance
        .collection('propertask')
        .doc('tarefas')
        .collection('tarefas')
        .doc(widget.tarefaId)
        .update({key: updatedList});
    if (!mounted) return;
    await _loadData();
  }

  Future<void> _deleteImage(String url, {bool fromLockbox = false}) async {
    final key = fromLockbox ? 'lockboxFotos' : 'fotos';
    final list = List<String>.from(data[key] ?? []);
    list.remove(url);
    await FirebaseFirestore.instance
        .collection('propertask')
        .doc('tarefas')
        .collection('tarefas')
        .doc(widget.tarefaId)
        .update({key: list});
    if (!mounted) return;
    await _loadData();
  }

  Future<void> _setInicio() async {
    await FirebaseFirestore.instance
        .collection('propertask')
        .doc('tarefas')
        .collection('tarefas')
        .doc(widget.tarefaId)
        .update({
          'status': 'em_andamento',
          'inicioEm': FieldValue.serverTimestamp(),
        });
    if (!mounted) return;
    await _loadData();
  }

  Future<void> _concluir() async {
    await FirebaseFirestore.instance
        .collection('propertask')
        .doc('tarefas')
        .collection('tarefas')
        .doc(widget.tarefaId)
        .update({
          'status': 'concluida',
          'concluidaEm': FieldValue.serverTimestamp(),
        });
    if (!mounted) return;
    await _loadData();
  }

  Future<void> _reabrir() async {
    await FirebaseFirestore.instance
        .collection('propertask')
        .doc('tarefas')
        .collection('tarefas')
        .doc(widget.tarefaId)
        .update({'status': 'pendente'});
    if (!mounted) return;
    await _loadData();
  }

  Future<void> _share() async {
    if (selectedShareUrls.isEmpty) {
      setState(() => selectedShareUrls = Set<String>.from(taskPhotos));
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Escolha as imagens para compartilhar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              children: taskPhotos
                  .map(
                    (url) => GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selectedShareUrls.contains(url)) {
                            selectedShareUrls.remove(url);
                          } else {
                            selectedShareUrls.add(url);
                          }
                        });
                        setModal(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedShareUrls.contains(url)
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.withAlpha(90),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Image.network(
                          url,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: selectedShareUrls.isEmpty
                  ? null
                  : () async {
                      final files = selectedShareUrls
                          .map((u) => XFile(u, mimeType: 'image/jpeg'))
                          .toList();
                      if (!mounted) return;
                      await SharePlus.instance.share(
                        ShareParams(
                          files: files,
                          text: "Fotos da tarefa de $tipo da propriedade $prop",
                        ),
                      );
                    },
              icon: const Icon(Icons.send),
              label: const Text('Compartilhar via WhatsApp/Outros'),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final podeIniciar = isLimpeza && status == 'pendente';
    final podeConcluir =
        isLimpeza && status == 'em_andamento' && taskPhotos.isNotEmpty;
    final podeReabrir = status == 'concluida';

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          padding: const EdgeInsets.only(
            top: 36,
            left: 22,
            right: 22,
            bottom: 14,
          ),
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(34),
              bottomRight: Radius.circular(34),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackButton(color: Colors.white),
              Text(
                prop,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  getTipoIcon(tipo, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    tipo.toString().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Chip(
            label: Text(
              _formatStatus(status),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: _getStatusColor(status, cs),
          ),
          const SizedBox(height: 18),
          _labelValue('Data', dataStr),
          _labelValue('Tipo', tipo.toString().toUpperCase()),
          if (isGestor) _labelValue('Responsável', respName),
          if (obs.isNotEmpty) _labelValue('Observações', obs),
          const SizedBox(height: 23),
          _SectionTitle(title: 'Imagens da tarefa'),
          Wrap(
            children: taskPhotos
                .map(
                  (url) => Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            url,
                            width: 82,
                            height: 82,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () => _deleteImage(url),
                          tooltip: 'Excluir imagem',
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Adicionar imagens da tarefa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _uploadMultipleImages(),
          ),
          if (isLockbox) ...[
            const SizedBox(height: 16),
            _SectionTitle(title: 'Imagens Lockbox'),
            Wrap(
              children: lockboxPhotos
                  .map(
                    (url) => Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(3),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              url,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 16,
                            ),
                            onPressed: () =>
                                _deleteImage(url, fromLockbox: true),
                            tooltip: 'Excluir imagem',
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            ElevatedButton.icon(
              icon: const Icon(Icons.lock),
              label: const Text('Adicionar imagens da lockbox'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _uploadMultipleImages(forLockbox: true),
            ),
          ],
          const SizedBox(height: 23),
          Row(
            children: [
              if (podeIniciar)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _setInicio,
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
                    onPressed: _concluir,
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
                    onPressed: _reabrir,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reabrir'),
                  ),
                ),
              if ((isGestor && status == 'concluida')) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: taskPhotos.isEmpty ? null : _share,
                    icon: const Icon(Icons.share),
                    label: const Text('Compartilhar fotos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelValue(String label, String value) => value.isEmpty
      ? const SizedBox()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Expanded(
                child: Text(value, style: const TextStyle(fontSize: 15)),
              ),
            ],
          ),
        );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
    ),
  );
}

// Utils
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
