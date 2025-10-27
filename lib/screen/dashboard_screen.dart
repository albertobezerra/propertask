import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/models/propriedade.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/services/firestore_service.dart';
import 'package:propertask/screen/equipe_screen.dart';
import 'package:propertask/screen/propriedade_detalhe_screen.dart';
import 'package:propertask/screen/relatorios_screen.dart';
import 'package:propertask/widgets/custom_text_field.dart';
import 'package:propertask/widgets/loading_widget.dart';
/*
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
*/

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FirestoreService _firestoreService = FirestoreService();

  void _adicionarPropriedade(BuildContext context) {
    TextEditingController _nomeController = TextEditingController();
    TextEditingController _enderecoController = TextEditingController();
    // XFile? _imageFile; // Para upload de imagens (futuro)

    /*
    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    }
    */

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova Propriedade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _nomeController,
              hintText: 'Nome da propriedade',
            ),
            CustomTextField(
              controller: _enderecoController,
              hintText: 'Localização',
            ),
            /*
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Selecionar Imagem'),
            ),
            if (_imageFile != null) Text('Imagem selecionada: ${_imageFile!.name}'),
            */
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_nomeController.text.isNotEmpty) {
                try {
                  /*
                  String? imageUrl;
                  if (_imageFile != null) {
                    final cloudinary = CloudinaryPublic('seu_cloud_name', 'seu_upload_preset');
                    final response = await cloudinary.uploadFile(
                      CloudinaryFile.fromFile(_imageFile!.path,
                          folder: 'propertask/${DateTime.now().millisecondsSinceEpoch}'),
                    );
                    imageUrl = response.secureUrl;
                    debugPrint('✅ Imagem enviada: $imageUrl');
                  }
                  */
                  final propriedade = Propriedade(
                    id: '',
                    nome: _nomeController.text,
                    localizacao: _enderecoController.text,
                    criadoEm: DateTime.now(),
                    // imageUrl: imageUrl, // Para upload de imagens (futuro)
                  );
                  await _firestoreService.addPropriedade(propriedade);
                  debugPrint(
                    '✅ Propriedade adicionada: ${_nomeController.text}',
                  );
                  Navigator.pop(context);
                } catch (e) {
                  debugPrint('❌ Erro ao adicionar propriedade: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao adicionar propriedade: $e'),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('O nome da propriedade é obrigatório.'),
                  ),
                );
              }
            },
            child: const Text('Adicionar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    debugPrint('Dashboard: Iniciando build, Usuário: ${appState.user?.uid}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propertask - Dashboard'),
        actions: [
          IconButton(
            icon: Icon(
              appState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              appState.toggleDarkMode();
            },
          ),
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              debugPrint('Navegando para EquipeScreen');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EquipeScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              debugPrint('Navegando para RelatoriosScreen');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RelatoriosScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomTextField(
              controller: _searchController,
              hintText: 'Pesquisar propriedades',
              prefixIcon: Icons.search,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Propriedade>>(
              stream: _firestoreService.getPropriedades(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  debugPrint('StreamBuilder: Aguardando dados');
                  return const LoadingWidget();
                }
                if (snapshot.hasError) {
                  debugPrint('Erro no StreamBuilder: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Erro ao carregar propriedades: ${snapshot.error}',
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  debugPrint('StreamBuilder: Nenhuma propriedade encontrada');
                  return const Center(
                    child: Text(
                      'Nenhuma propriedade encontrada. Clique em "+" para adicionar.',
                    ),
                  );
                }

                final propriedades = snapshot.data!
                    .where(
                      (prop) =>
                          prop.nome.toLowerCase().contains(_searchQuery) ||
                          prop.localizacao.toLowerCase().contains(_searchQuery),
                    )
                    .toList();

                debugPrint(
                  'StreamBuilder: ${propriedades.length} propriedades filtradas',
                );
                return ListView.builder(
                  itemCount: propriedades.length,
                  itemBuilder: (context, index) {
                    var propriedade = propriedades[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      child: ListTile(
                        title: Text(propriedade.nome),
                        subtitle: Text(propriedade.localizacao),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          debugPrint(
                            'Navegando para PropriedadeDetalheScreen: ${propriedade.id}',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PropriedadeDetalheScreen(
                                propriedadeId: propriedade.id,
                                propriedadeNome: propriedade.nome,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _adicionarPropriedade(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
