import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';
import 'package:propertask/core/services/storage_service.dart';

// WIDGETS REFATORADOS
import 'widgets/tarefa_app_bar.dart';
import 'widgets/tarefa_info_card.dart';
import 'widgets/tarefa_fotos_section.dart';
import 'widgets/tarefa_actions_bar.dart';
import 'widgets/tarefa_status_card.dart';

class TarefaDetalheScreen extends StatefulWidget {
  final String tarefaId;
  const TarefaDetalheScreen({super.key, required this.tarefaId});

  @override
  State<TarefaDetalheScreen> createState() => _TarefaDetalheScreenState();
}

class _TarefaDetalheScreenState extends State<TarefaDetalheScreen> {
  // --- ESTADO ---
  Map<String, dynamic> data = {};
  bool loading = true;
  List<String> taskPhotos = [];
  List<File> localTaskPhotos = [];
  late String status = '',
      tipo = '',
      prop = '',
      obs = '',
      respName = '',
      dataStr = '',
      propId = '';
  late bool isGestor = false, isAtribuido = false, isLimpeza = false;
  String? cargo;
  DateTime? inicioEm, concluidaEm;
  String? inicioGeo, concluidaGeo;
  Map<String, dynamic>? propriedadeData;
  late String empresaId;

  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    empresaId = Provider.of<AppState>(context, listen: false).empresaId!;
    _setupFirestoreListener();
  }

  void _setupFirestoreListener() {
    FirebaseFirestore.instance
        .collection('empresas')
        .doc(empresaId)
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
            propId = data['propriedadeId'] ?? '';
            respName = data['responsavelNome'] ?? '—';
            taskPhotos = List<String>.from(data['fotos'] ?? []);

            final usuario = Provider.of<AppState>(
              context,
              listen: false,
            ).usuario!;
            cargo = usuario.cargo;
            isLimpeza = Permissions.cargoFromString(cargo!) == Cargo.limpeza;
            isGestor = [
              Cargo.dev,
              Cargo.coordenador,
              Cargo.ceo,
              Cargo.supervisor,
            ].contains(Permissions.cargoFromString(cargo!));
            isAtribuido = (data['responsavelId'] ?? '') == usuario.id;

            dataStr = data['data'] is Timestamp
                ? DateFormat(
                    'dd/MM/yyyy',
                  ).format((data['data'] as Timestamp).toDate())
                : '';
            inicioEm = data['inicioEm'] is Timestamp
                ? (data['inicioEm'] as Timestamp).toDate()
                : null;
            concluidaEm = data['concluidaEm'] is Timestamp
                ? (data['concluidaEm'] as Timestamp).toDate()
                : null;
            inicioGeo = data['inicioGeo'] as String?;
            concluidaGeo = data['concluidaGeo'] as String?;
            loading = false;
          });

          if (d['propriedadeId'] != null && propriedadeData == null) {
            _loadPropriedade(d['propriedadeId']);
          }
        });
  }

  Future<void> _loadPropriedade(String pId) async {
    final doc = await FirebaseFirestore.instance
        .collection('empresas')
        .doc(empresaId)
        .collection('propriedades')
        .doc(pId)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        propriedadeData = doc.data();
      });
    }
  }

  // --- AÇÕES ---

  Future<void> _getLocationAndTime(String fieldTime, String fieldGeo) async {
    try {
      final location = Location();
      final locData = await location.getLocation();
      final geo =
          '${locData.latitude?.toStringAsFixed(5)},${locData.longitude?.toStringAsFixed(5)}';
      await FirebaseFirestore.instance
          .collection('empresas')
          .doc(empresaId)
          .collection('tarefas')
          .doc(widget.tarefaId)
          .update({fieldTime: FieldValue.serverTimestamp(), fieldGeo: geo});
    } catch (_) {}
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => loading = true);
    await FirebaseFirestore.instance
        .collection('empresas')
        .doc(empresaId)
        .collection('tarefas')
        .doc(widget.tarefaId)
        .update({'status': newStatus});

    if (newStatus == 'em_andamento') {
      await _getLocationAndTime('inicioEm', 'inicioGeo');
    }
    if (newStatus == 'concluida') {
      await _getLocationAndTime('concluidaEm', 'concluidaGeo');
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> _reabrirTarefa() async {
    setState(() => loading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance
        .collection('empresas')
        .doc(empresaId)
        .collection('tarefas')
        .doc(widget.tarefaId)
        .update({'status': 'reaberta', 'reabertaPor': userId});
    if (mounted) setState(() => loading = false);
  }

  // --- IMAGENS ---

  Future<File> _compressImage(File file) async {
    final targetPath = file.path.replaceFirst(
      RegExp(r'\.(jpg|jpeg|png)$', caseSensitive: false),
      '_compressed.jpg',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 82,
      minWidth: 1600,
      minHeight: 1600,
      format: CompressFormat.jpeg,
    );
    return result != null ? File(result.path) : file;
  }

  Future<void> _uploadFoto(XFile img) async {
    final original = File(img.path);
    final file = await _compressImage(original);
    final fileName =
        '${widget.tarefaId}_${DateTime.now().millisecondsSinceEpoch}_${img.name}';

    final ref = FirebaseStorage.instance.ref().child(
      'empresas/$empresaId/tarefas/$propId/${widget.tarefaId}/$fileName',
    );
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    final updatedList = [...taskPhotos, url];
    await FirebaseFirestore.instance
        .collection('empresas')
        .doc(empresaId)
        .collection('tarefas')
        .doc(widget.tarefaId)
        .update({'fotos': updatedList});

    if (mounted) {
      setState(() {
        localTaskPhotos.removeWhere((f) => f.path == img.path);
      });
    }
  }

  Future<void> _adicionarImagens() async {
    final picker = ImagePicker();
    final List<XFile> imagens = await picker.pickMultiImage(imageQuality: 100);
    if (imagens.isEmpty) return;

    setState(() {
      localTaskPhotos.addAll(imagens.map((img) => File(img.path)));
    });

    for (final img in imagens) {
      await _uploadFoto(img);
    }
  }

  Future<void> _adicionarImagemCamera() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    if (img == null) return;

    setState(() {
      localTaskPhotos.add(File(img.path));
    });
    await _uploadFoto(img);
  }

  Future<void> _deleteImage(String url) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir foto?'),
        content: const Text('A foto será apagada permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _storageService.deleteImageByUrl(url);
      final list = List<String>.from(taskPhotos)..remove(url);
      await FirebaseFirestore.instance
          .collection('empresas')
          .doc(empresaId)
          .collection('tarefas')
          .doc(widget.tarefaId)
          .update({'fotos': list});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
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
            title: const Text('Galeria'),
            onTap: () {
              Navigator.pop(context);
              _adicionarImagens();
            },
          ),
        ],
      ),
    );
  }

  // Substitua o método _mostrarGaleriaFotos atual por este:
  void _mostrarGaleriaFotos(BuildContext context, int indexInicial) {
    final pageController = PageController(initialPage: indexInicial);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9), // Fundo escuro
      builder: (ctx) {
        int atual = indexInicial;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // 1. A GALERIA
                  Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.95,
                        maxHeight: MediaQuery.of(context).size.height * 0.85,
                      ),
                      child: PhotoViewGallery.builder(
                        scrollPhysics: const BouncingScrollPhysics(),
                        itemCount: taskPhotos.length,
                        pageController: pageController,
                        onPageChanged: (index) {
                          setModalState(() => atual = index);
                        },
                        builder: (context, index) {
                          return PhotoViewGalleryPageOptions(
                            imageProvider: NetworkImage(taskPhotos[index]),
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 2,
                            heroAttributes: PhotoViewHeroAttributes(
                              tag: taskPhotos[index],
                            ),
                          );
                        },
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),

                  // 2. BOTÃO FECHAR (X)
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // 3. CONTADOR / BOLINHAS
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(taskPhotos.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: atual == i ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: atual == i ? Colors.white : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- UTILS MAPA ---
  Future<void> _abrirEscolhaMapa(BuildContext context, String endereco) async {
    try {
      final available = await MapLauncher.installedMaps;
      if (available.isEmpty) {
        final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(endereco)}',
        );
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: available.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              title: Text(available[i].mapName),
              onTap: () {
                available[i].showMarker(
                  coords: Coords(0, 0),
                  title: endereco,
                  extraParams: {'q': endereco},
                );
              },
            ),
          ),
        ),
      );
    } catch (_) {}
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    if (loading && data.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final podeIniciar = isAtribuido && status == 'pendente';
    final podeConcluir =
        isAtribuido &&
        (status == 'em_andamento' || status == 'reaberta') &&
        taskPhotos.isNotEmpty;
    final podeReabrir = isGestor && status == 'concluida';

    return Scaffold(
      appBar: TarefaAppBar(tipo: tipo, propriedadeNome: prop),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // 1. Informações da Propriedade (Widget Refatorado)
          TarefaInfoCard(
            propriedadeData: propriedadeData,
            tipoTarefa: tipo,
            onAddressTap: () => _abrirEscolhaMapa(
              context,
              propriedadeData?['endereco'] ?? propriedadeData?['cidade'] ?? '',
            ),
          ),

          // 2. CARD DE STATUS UNIFICADO (NOVO)
          TarefaStatusCard(
            status: status,
            responsavelNome: respName,
            dataFormatada: dataStr,
            inicioEm: inicioEm,
            concluidaEm: concluidaEm,
          ),

          const SizedBox(height: 16),

          // 4. Seção de Fotos (Widget Refatorado)
          TarefaFotosSection(
            status: status,
            isAtribuido: isAtribuido,
            taskPhotos: taskPhotos,
            localTaskPhotos: localTaskPhotos,
            onAddPhoto: () => _escolherTipoImagem(context),
            onOpenGallery: (i) => _mostrarGaleriaFotos(context, i),
            onDeletePhoto: _deleteImage,
          ),

          const SizedBox(height: 24),

          // 5. Botões de Ação (Widget Refatorado)
          TarefaActionsBar(
            loading: loading && data.isNotEmpty, // Loading dos botões
            podeIniciar: podeIniciar,
            podeConcluir: podeConcluir,
            podeReabrir: podeReabrir,
            onIniciar: () => _updateStatus('em_andamento'),
            onConcluir: () => _updateStatus('concluida'),
            onReabrir: _reabrirTarefa,
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar local para Status (Pequeno demais para arquivo separado, mas pode separar se quiser)
// ignore: unused_element
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
          'pendente': 'Aguardando',
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
