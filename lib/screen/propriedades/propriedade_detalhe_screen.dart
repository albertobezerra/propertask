// lib/screen/propriedades/propriedade_detalhe_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/utils/permissions.dart';
import 'package:propertask/screen/propriedades/propriedade_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PropriedadeDetalheScreen extends StatelessWidget {
  final String propriedadeId;
  const PropriedadeDetalheScreen({super.key, required this.propriedadeId});

  @override
  Widget build(BuildContext context) {
    final cargo = Provider.of<AppState>(context).usuario?.cargo ?? 'LIMPEZA';
    final podeEditar = Permissions.podeGerenciarPropriedades(cargo);

    final empresaId = Provider.of<AppState>(context, listen: false).empresaId!;
    final docRef = FirebaseFirestore.instance
        .collection('empresas')
        .doc(empresaId)
        .collection('propriedades')
        .doc(propriedadeId);

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Propriedade não encontrada')),
          );
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

        final cafeRaw = data['cafe'];
        final cafe = (cafeRaw == null || cafeRaw.toString().trim().isEmpty)
            ? 'Sem café'
            : cafeRaw.toString();

        final levarChave = data['levarChave'] == true;
        final codigoPredio = (data['codigoPredio'] ?? '').toString();
        final codigoApartamento = (data['codigoApartamento'] ?? '').toString();
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

        final roupaMap = (data['roupa'] is Map)
            ? Map<String, dynamic>.from(data['roupa'])
            : const <String, dynamic>{};

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 240,
                title: Text(nome, overflow: TextOverflow.ellipsis, maxLines: 1),
                actions: [
                  if (podeEditar)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar',
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final snap = await docRef.get();
                        await navigator.push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PropriedadeFormScreen(propriedade: snap),
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
                              const SnackBar(
                                content: Text('Propriedade excluída'),
                              ),
                            );
                            navigator.pop();
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
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (fotoUrl.isNotEmpty)
                        Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, err, stack) => _placeholderHeader(),
                        )
                      else
                        _placeholderHeader(),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black26],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                sliver: SliverList.list(
                  children: [
                    // Endereço clicável
                    _addressCard(
                      context,
                      completo,
                      () => _abrirEscolhaMapa(context, sanitizedForMap),
                    ),

                    const SizedBox(height: 12),

                    // Chips principais
                    _pillsCard(
                      context,
                      cidade: cidade,
                      codigoPostal: codigoPostal,
                      tipologia: tipologia,
                      banhos: banhos,
                      sofaCama: sofaCama,
                    ),

                    const SizedBox(height: 12),

                    // Acessos
                    if (levarChave ||
                        codigoPredio.isNotEmpty ||
                        codigoApartamento.isNotEmpty ||
                        temLockbox)
                      _sectionCard(
                        context,
                        icon: Icons.vpn_key,
                        title: 'Acessos',
                        children: [
                          if (levarChave)
                            _tile(
                              icon: Icons.key,
                              title: 'Levar chave',
                              subtitle: 'Sim',
                            ),
                          if (codigoPredio.isNotEmpty)
                            _tile(
                              icon: Icons.domain,
                              title: 'Código do prédio',
                              subtitle: codigoPredio,
                            ),
                          if (codigoApartamento.isNotEmpty)
                            _tile(
                              icon: Icons.meeting_room,
                              title: 'Código do apartamento',
                              subtitle: codigoApartamento,
                            ),
                          if (temLockbox) ...[
                            _tile(
                              icon: Icons.lock_outline,
                              title: 'Lockbox',
                              subtitle: 'Sim',
                            ),
                            if (lockboxCodigo.isNotEmpty)
                              _tile(
                                icon: Icons.pin,
                                title: 'Código da lockbox',
                                subtitle: lockboxCodigo,
                              ),
                            if (lockboxLocal.isNotEmpty)
                              _tile(
                                icon: Icons.place,
                                title: 'Local da lockbox',
                                subtitle: lockboxLocal,
                              ),
                          ],
                        ],
                      ),

                    const SizedBox(height: 12),

                    // Amenidades/fornecimento
                    _sectionCard(
                      context,
                      icon: Icons.coffee,
                      title: 'Amenidades e fornecimento',
                      children: [
                        _tile(
                          icon: Icons.coffee,
                          title: 'Café',
                          subtitle: cafe,
                        ),
                        if (fornecedorRoupa.isNotEmpty)
                          _tile(
                            icon: Icons.local_laundry_service,
                            title: 'Fornecedor de roupa',
                            subtitle: fornecedorRoupa,
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Roupas e lavanderia
                    if (_temItensRoupa(roupaMap)) _roupaCard(context, roupaMap),

                    const SizedBox(height: 12),

                    // Placeholder de fotos adicionais
                    _sectionCard(
                      context,
                      icon: Icons.photo_library_outlined,
                      title: 'Fotos',
                      children: const [
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.info_outline),
                          title: Text('Fotos adicionais: (em breve)'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Helpers de UI ----------

  Widget _addressCard(
    BuildContext context,
    String endereco,
    VoidCallback onTap,
  ) {
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

  Widget _pillsCard(
    BuildContext context, {
    required String cidade,
    required String codigoPostal,
    required String tipologia,
    required int banhos,
    required bool sofaCama,
  }) {
    final cs = Theme.of(context).colorScheme;
    final chips = <Widget>[
      if (cidade.isNotEmpty)
        Chip(
          label: Text(cidade),
          visualDensity: VisualDensity.compact,
          backgroundColor: cs.primaryContainer,
          labelStyle: TextStyle(color: cs.onPrimaryContainer),
        ),
      if (codigoPostal.isNotEmpty)
        Chip(
          label: Text(codigoPostal),
          visualDensity: VisualDensity.compact,
          backgroundColor: cs.primaryContainer,
          labelStyle: TextStyle(color: cs.onPrimaryContainer),
        ),
      if (tipologia.isNotEmpty)
        Chip(
          label: Text(tipologia),
          visualDensity: VisualDensity.compact,
          backgroundColor: cs.primaryContainer,
          labelStyle: TextStyle(color: cs.onPrimaryContainer),
        ),
      Chip(
        label: Text(_rotuloCasasBanho(banhos)),
        visualDensity: VisualDensity.compact,
        backgroundColor: cs.primaryContainer,
        labelStyle: TextStyle(color: cs.onPrimaryContainer),
      ),
      if (sofaCama)
        Chip(
          label: const Text('Sofá‑cama'),
          visualDensity: VisualDensity.compact,
          backgroundColor: cs.primaryContainer,
          labelStyle: TextStyle(color: cs.onPrimaryContainer),
        ),
    ];

    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Wrap(spacing: 8, runSpacing: -8, children: chips),
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

  bool _temItensRoupa(Map<String, dynamic> roupa) {
    if (roupa.isEmpty) return false;
    for (final v in roupa.values) {
      final qtd = v is int
          ? v
          : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
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
      'lençol_casal': asIntLocal(
        roupa['lençol_casal'] ?? roupa['lencol_casal'],
      ),
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

  // ---------- Ações e utilitários ----------

  Future<void> _abrirEscolhaMapa(
    BuildContext context,
    String enderecoLimpo,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final available = await MapLauncher.installedMaps;
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
}
