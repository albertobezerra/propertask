// lib/screen/propriedades/propriedade_detalhe_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:propertask/screen/propriedades/propriedade_form_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';
import 'package:map_launcher/map_launcher.dart';

class PropriedadeDetalheScreen extends StatelessWidget {
  final String propriedadeId;

  const PropriedadeDetalheScreen({super.key, required this.propriedadeId});

  @override
  Widget build(BuildContext context) {
    final cargo = Provider.of<AppState>(context).usuario?.cargo ?? 'LIMPEZA';
    final podeEditar = Permissions.podeGerenciarPropriedades(cargo);

    final docRef = FirebaseFirestore.instance
        .collection('propertask')
        .doc('propriedades')
        .collection('propriedades')
        .doc(propriedadeId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Propriedade'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true, // seta de voltar automática
        actions: [
          if (podeEditar)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
              onPressed: () async {
                final navigator = Navigator.of(
                  context,
                ); // capture antes do await
                final snap = await docRef.get();
                await navigator.push(
                  MaterialPageRoute(
                    builder: (_) => PropriedadeFormScreen(propriedade: snap),
                  ),
                );
              },
            ),
          if (podeEditar)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Excluir',
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Excluir?'),
                    content: const Text(
                      'Tem certeza que deseja excluir esta propriedade?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => navigator.pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => navigator.pop(true),
                        child: const Text(
                          'Excluir',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (ok == true) {
                  try {
                    await docRef.delete();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Propriedade excluída')),
                    );
                    navigator.pop(); // volta para a lista
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Erro: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('Propriedade não encontrada'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final nome = (data['nome'] ?? 'Sem nome').toString();
          final endereco = (data['endereco'] ?? '').toString();

          final rua = (data['enderecoRua'] ?? '').toString();
          final numero = (data['enderecoNumero'] ?? '').toString();
          final complemento = (data['enderecoComplemento'] ?? '').toString();
          final bairro = (data['enderecoBairro'] ?? '').toString();
          final cidade = (data['cidade'] ?? '').toString();
          final distrito = (data['distrito'] ?? '').toString();
          final pais = (data['pais'] ?? '').toString();
          final codigoPostal = (data['codigoPostal'] ?? '').toString();

          final tipologia = (data['tipologia'] ?? '').toString();
          final banhos = (data['banhos'] ?? 0) as int;
          final sofaCama = data['sofaCama'] == true;
          final cafe = (data['cafe'] ?? '').toString();

          final levarChave = data['levarChave'] == true;
          final codigoPredio = (data['codigoPredio'] ?? '').toString();
          final codigoApartamento = (data['codigoApartamento'] ?? '')
              .toString();
          final temLockbox = data['temLockbox'] == true;
          final lockboxCodigo = (data['lockboxCodigo'] ?? '').toString();
          final lockboxLocal = (data['lockboxLocal'] ?? '').toString();

          final fornecedorRoupa = (data['fornecedorRoupa'] ?? '').toString();
          final fotoUrl = (data['fotoUrl'] ?? '').toString();

          final completo = endereco.isNotEmpty
              ? endereco
              : _montarEndereco(
                  rua: rua,
                  numero: numero,
                  complemento: complemento,
                  bairro: bairro,
                  cidade: cidade,
                  distrito: distrito,
                  codigoPostal: codigoPostal,
                  pais: pais,
                );

          final sanitizedForMap = _sanitizarEnderecoParaMapa(
            rua: rua,
            numero: numero,
            bairro: bairro,
            cidade: cidade,
            distrito: distrito,
            codigoPostal: codigoPostal,
            pais: pais,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: fotoUrl.isNotEmpty
                      ? Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholderHeader(),
                        )
                      : _placeholderHeader(),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                nome,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Endereço clicável (discreto, sem sublinhado/azul)
              InkWell(
                onTap: () => _abrirEscolhaMapa(context, sanitizedForMap),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          completo.isNotEmpty ? completo : 'Sem endereço',
                          style: const TextStyle(color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      //const Icon(Icons.map, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: -8,
                children: [
                  if (cidade.isNotEmpty)
                    Chip(
                      label: Text(cidade),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (codigoPostal.isNotEmpty)
                    Chip(
                      label: Text(codigoPostal),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (tipologia.isNotEmpty)
                    Chip(
                      label: Text(tipologia),
                      visualDensity: VisualDensity.compact,
                    ),
                  Chip(
                    label: Text(
                      _rotuloCasasBanho(banhos),
                    ), // “casa(s) de banho”
                    visualDensity: VisualDensity.compact,
                  ),
                  if (sofaCama)
                    Chip(
                      label: const Text('Sofá‑cama'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (levarChave ||
                  codigoPredio.isNotEmpty ||
                  codigoApartamento.isNotEmpty ||
                  temLockbox) ...[
                Text('Acessos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (levarChave) _infoRow('Levar chave', 'Sim'),
                if (codigoPredio.isNotEmpty)
                  _infoRow('Código do prédio', codigoPredio),
                if (codigoApartamento.isNotEmpty)
                  _infoRow('Código do apartamento', codigoApartamento),
                if (temLockbox) ...[
                  _infoRow('Lockbox', 'Sim'),
                  if (lockboxCodigo.isNotEmpty)
                    _infoRow('Código da lockbox', lockboxCodigo),
                  if (lockboxLocal.isNotEmpty)
                    _infoRow('Local da lockbox', lockboxLocal),
                ],
                const SizedBox(height: 16),
              ],

              if (cafe.isNotEmpty || fornecedorRoupa.isNotEmpty) ...[
                Text(
                  'Amenidades e fornecimento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (cafe.isNotEmpty) _infoRow('Café', cafe),
                if (fornecedorRoupa.isNotEmpty)
                  _infoRow('Fornecedor de roupa', fornecedorRoupa),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 12),
              const Text(
                'Fotos adicionais: (em breve)',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _abrirEscolhaMapa(
    BuildContext context,
    String enderecoLimpo,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final available =
          await MapLauncher.installedMaps; // dinâmico por dispositivo
      if (available.isEmpty) {
        final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(enderecoLimpo)}',
        );
        final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!ok) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o mapa')),
          );
        }
        return;
      }

      if (!context.mounted) return;

      // ignore: use_build_context_synchronously
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
              separatorBuilder: (context, _) => Divider(height: 1),
              itemBuilder: (context, i) {
                final m = available[i];
                return ListTile(
                  leading: const Icon(
                    Icons.map,
                    size: 24,
                  ), // ícone genérico, sem SVG
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
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir opções de mapas')),
      );
    }
  }

  String _montarEndereco({
    required String rua,
    required String numero,
    required String complemento,
    required String bairro,
    required String cidade,
    required String distrito,
    required String codigoPostal,
    required String pais,
  }) {
    final parts = <String>[
      rua,
      numero.isNotEmpty ? numero : '',
      complemento.isNotEmpty ? complemento : '',
      bairro.isNotEmpty ? bairro : '',
      cidade,
      distrito.isNotEmpty ? distrito : '',
      codigoPostal.isNotEmpty ? codigoPostal : '',
      pais,
    ].where((e) => e.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  String _sanitizarEnderecoParaMapa({
    required String rua,
    required String numero,
    required String bairro,
    required String cidade,
    required String distrito,
    required String codigoPostal,
    required String pais,
  }) {
    final parts = <String>[
      rua,
      numero,
      bairro,
      cidade,
      distrito,
      codigoPostal,
      pais,
    ].where((e) => e.trim().isNotEmpty).toList();
    final s = parts.join(' ').replaceAll(',', ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _rotuloCasasBanho(int banhos) {
    if (banhos == 1) return '1 casa de banho';
    return '$banhos casas de banho';
  }

  Widget _placeholderHeader() {
    return Container(
      color: Colors.blueGrey.shade100,
      child: const Center(
        child: Icon(Icons.home, color: Colors.blueGrey, size: 64),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}
