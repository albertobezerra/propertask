// lib/screen/propriedades/propriedade_form_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:provider/provider.dart';

class PropriedadeFormScreen extends StatefulWidget {
  final DocumentSnapshot? propriedade;
  const PropriedadeFormScreen({super.key, this.propriedade});

  @override
  State<PropriedadeFormScreen> createState() => _PropriedadeFormScreenState();
}

class _PropriedadeFormScreenState extends State<PropriedadeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Identificação e endereço
  late TextEditingController _nome,
      _rua,
      _numero,
      _complemento,
      _bairro,
      _cidade,
      _distrito,
      _pais,
      _codigoPostal;

  // Tipologia/detalhes
  String _tipologia = 'T1';
  int _banhos = 1;
  bool _sofaCama = false;
  String _cafe = 'Sem café';

  // Acesso
  bool _levarChave = true;
  late TextEditingController _codigoPredio, _codigoApartamento;
  bool _temLockbox = false;
  late TextEditingController _lockboxLocal, _lockboxCodigo;

  // Fornecedor
  String _fornecedorRoupa = 'Loja';

  // Roupas e lavanderia (quantidades)
  int _qFronha = 0;
  int _qLencolCasal = 0;
  int _qCapaCasal = 0;
  int _qLencolSolteiro = 0;
  int _qCapaSolteiro = 0;
  int _qToalhaBanho = 0;
  int _qToalhaRosto = 0;
  int _qTapete = 0;
  int _qPanoLimpeza = 0;

  @override
  void initState() {
    super.initState();
    final data = widget.propriedade?.data() as Map<String, dynamic>? ?? {};
    _nome = TextEditingController(text: data['nome'] ?? '');
    _rua = TextEditingController(text: data['enderecoRua'] ?? '');
    _numero = TextEditingController(text: data['enderecoNumero'] ?? '');
    _complemento = TextEditingController(
      text: data['enderecoComplemento'] ?? '',
    );
    _bairro = TextEditingController(text: data['enderecoBairro'] ?? '');
    _cidade = TextEditingController(text: data['cidade'] ?? '');
    _distrito = TextEditingController(text: data['distrito'] ?? '');
    _pais = TextEditingController(text: data['pais'] ?? 'Portugal');
    _codigoPostal = TextEditingController(text: data['codigoPostal'] ?? '');

    _tipologia = (data['tipologia'] ?? 'T1').toString();
    _banhos = _asInt(data['banhos'], 1);
    _sofaCama = data['sofaCama'] == true;

    final cafeRaw = data['cafe'];
    _cafe = (cafeRaw == null || cafeRaw.toString().trim().isEmpty)
        ? 'Sem café'
        : cafeRaw.toString();

    _levarChave = data['levarChave'] != false;
    _codigoPredio = TextEditingController(text: data['codigoPredio'] ?? '');
    _codigoApartamento = TextEditingController(
      text: data['codigoApartamento'] ?? '',
    );

    _temLockbox = data['temLockbox'] == true;
    _lockboxLocal = TextEditingController(text: data['lockboxLocal'] ?? '');
    _lockboxCodigo = TextEditingController(text: data['lockboxCodigo'] ?? '');

    _fornecedorRoupa = (data['fornecedorRoupa'] ?? 'Loja').toString();

    final roupa = (data['roupa'] is Map)
        ? Map<String, dynamic>.from(data['roupa'])
        : {};
    _qFronha = _asInt(roupa['fronha']);
    _qLencolCasal = _asInt(roupa['lençol_casal'] ?? roupa['lencol_casal']);
    _qCapaCasal = _asInt(roupa['capa_casal']);
    _qLencolSolteiro = _asInt(
      roupa['lençol_solteiro'] ?? roupa['lencol_solteiro'],
    );
    _qCapaSolteiro = _asInt(roupa['capa_solteiro']);
    _qToalhaBanho = _asInt(roupa['toalha_banho']);
    _qToalhaRosto = _asInt(roupa['toalha_rosto']);
    _qTapete = _asInt(roupa['tapete']);
    _qPanoLimpeza = _asInt(roupa['pano_limpeza']);
  }

  int _asInt(dynamic v, [int def = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  @override
  void dispose() {
    _nome.dispose();
    _rua.dispose();
    _numero.dispose();
    _complemento.dispose();
    _bairro.dispose();
    _cidade.dispose();
    _distrito.dispose();
    _pais.dispose();
    _codigoPostal.dispose();
    _codigoPredio.dispose();
    _codigoApartamento.dispose();
    _lockboxLocal.dispose();
    _lockboxCodigo.dispose();
    super.dispose();
  }

  List<String> get _tipologias => List<String>.generate(10, (i) => 'T$i');
  List<String> get _cafes => const [
    'Sem café',
    'Delta Q',
    'Nespresso',
    'Dolce Gusto',
  ];
  List<String> get _fornecedores => const [
    'Loja',
    'Francês',
    'LovelyStay',
    'Santa Catarina',
    'Horácio',
  ];

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.propriedade != null;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _salvar,
        icon: const Icon(Icons.save),
        label: Text(isEdit ? 'Salvar' : 'Adicionar'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 80,
            title: Text(isEdit ? 'Editar Propriedade' : 'Nova Propriedade'),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Column(
                  children: [
                    // Identificação
                    _sectionCard(
                      context,
                      icon: Icons.home,
                      title: 'Identificação',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nome,
                            decoration: const InputDecoration(
                              labelText: 'Nome da propriedade *',
                              prefixIcon: Icon(Icons.home),
                            ),
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Obrigatório' : null,
                            textCapitalization: TextCapitalization.words,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Endereço
                    _sectionCard(
                      context,
                      icon: Icons.place,
                      title: 'Endereço',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _rua,
                            decoration: const InputDecoration(
                              labelText: 'Rua *',
                              prefixIcon: Icon(Icons.signpost),
                            ),
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Obrigatório' : null,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _numero,
                                  decoration: const InputDecoration(
                                    labelText: 'Número',
                                    prefixIcon: Icon(Icons.tag),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _complemento,
                                  decoration: const InputDecoration(
                                    labelText: 'Complemento',
                                    prefixIcon: Icon(Icons.add_home_work),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _bairro,
                            decoration: const InputDecoration(
                              labelText: 'Bairro',
                              prefixIcon: Icon(Icons.maps_home_work),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cidade,
                                  decoration: const InputDecoration(
                                    labelText: 'Cidade *',
                                    prefixIcon: Icon(Icons.location_city),
                                  ),
                                  validator: (v) =>
                                      v!.trim().isEmpty ? 'Obrigatório' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _distrito,
                                  decoration: const InputDecoration(
                                    labelText: 'Distrito',
                                    prefixIcon: Icon(Icons.map),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _pais,
                                  decoration: const InputDecoration(
                                    labelText: 'País *',
                                    prefixIcon: Icon(Icons.public),
                                  ),
                                  validator: (v) =>
                                      v!.trim().isEmpty ? 'Obrigatório' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _codigoPostal,
                                  decoration: const InputDecoration(
                                    labelText: 'Código Postal',
                                    prefixIcon: Icon(Icons.local_post_office),
                                    hintText: '1000-001',
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(8),
                                    FilteringTextInputFormatter.digitsOnly,
                                    _CodigoPostalPtFormatter(),
                                  ],
                                  validator: (v) {
                                    final s = (v ?? '').trim();
                                    if (s.isEmpty) return null;
                                    final re = RegExp(r'^\d{4}-\d{3}$');
                                    return re.hasMatch(s)
                                        ? null
                                        : 'Formato: NNNN-NNN';
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Detalhes
                    _sectionCard(
                      context,
                      icon: Icons.apartment,
                      title: 'Detalhes',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _tipologia,
                                  items: _tipologias
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _tipologia = v ?? 'T1'),
                                  decoration: const InputDecoration(
                                    labelText: 'Tipologia',
                                    prefixIcon: Icon(Icons.apartment),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _banhos,
                                  items: List<int>.generate(10, (i) => i)
                                      .map(
                                        (b) => DropdownMenuItem(
                                          value: b,
                                          child: Text('$b'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _banhos = v ?? 1),
                                  decoration: const InputDecoration(
                                    labelText: 'Casas de banho',
                                    prefixIcon: Icon(Icons.bathtub),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('Possui sofá‑cama'),
                            value: _sofaCama,
                            onChanged: (v) => setState(() => _sofaCama = v),
                            secondary: const Icon(Icons.event_seat),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Roupas e lavanderia
                    _sectionCard(
                      context,
                      icon: Icons.local_laundry_service,
                      title: 'Roupas e lavanderia',
                      trailing: TextButton.icon(
                        onPressed: _aplicarSugestaoRoupas,
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('Aplicar sugestão'),
                      ),
                      child: Column(
                        children: [
                          _qtyRow(
                            'Fronhas',
                            _qFronha,
                            Icons.bed,
                            (v) => setState(() => _qFronha = v),
                          ),
                          _qtyRow(
                            'Lençol de casal',
                            _qLencolCasal,
                            Icons.bedroom_parent,
                            (v) => setState(() => _qLencolCasal = v),
                          ),
                          _qtyRow(
                            'Capa de casal',
                            _qCapaCasal,
                            Icons.bedroom_parent,
                            (v) => setState(() => _qCapaCasal = v),
                          ),
                          _qtyRow(
                            'Lençol de solteiro',
                            _qLencolSolteiro,
                            Icons.single_bed,
                            (v) => setState(() => _qLencolSolteiro = v),
                          ),
                          _qtyRow(
                            'Capa de solteiro',
                            _qCapaSolteiro,
                            Icons.single_bed,
                            (v) => setState(() => _qCapaSolteiro = v),
                          ),
                          _qtyRow(
                            'Toalhas de banho',
                            _qToalhaBanho,
                            Icons.local_hotel,
                            (v) => setState(() => _qToalhaBanho = v),
                          ),
                          _qtyRow(
                            'Toalhas de rosto',
                            _qToalhaRosto,
                            Icons.face,
                            (v) => setState(() => _qToalhaRosto = v),
                          ),
                          _qtyRow(
                            'Tapetes de casa de banho',
                            _qTapete,
                            Icons.crop_portrait,
                            (v) => setState(() => _qTapete = v),
                          ),
                          _qtyRow(
                            'Panos de limpeza',
                            _qPanoLimpeza,
                            Icons.cleaning_services,
                            (v) => setState(() => _qPanoLimpeza = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Acessos
                    _sectionCard(
                      context,
                      icon: Icons.vpn_key,
                      title: 'Acessos',
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: const Text('Levar chave'),
                            value: _levarChave,
                            onChanged: (v) =>
                                setState(() => _levarChave = v ?? false),
                            secondary: const Icon(Icons.vpn_key),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          TextFormField(
                            controller: _codigoPredio,
                            decoration: const InputDecoration(
                              labelText: 'Código de acesso do prédio',
                              prefixIcon: Icon(Icons.domain),
                              hintText: 'Deixe vazio se não houver',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _codigoApartamento,
                            decoration: const InputDecoration(
                              labelText: 'Código de acesso do apartamento',
                              prefixIcon: Icon(Icons.meeting_room),
                              hintText: 'Deixe vazio se não houver',
                            ),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            title: const Text('Possui lockbox'),
                            value: _temLockbox,
                            onChanged: (v) =>
                                setState(() => _temLockbox = v ?? false),
                            secondary: const Icon(Icons.lock_outline),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_temLockbox) ...[
                            TextFormField(
                              controller: _lockboxCodigo,
                              decoration: const InputDecoration(
                                labelText: 'Código do lockbox',
                                prefixIcon: Icon(Icons.pin),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _lockboxLocal,
                              decoration: const InputDecoration(
                                labelText: 'Orientação/localização do lockbox',
                                prefixIcon: Icon(Icons.place),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amenidades e fornecedor
                    _sectionCard(
                      context,
                      icon: Icons.coffee,
                      title: 'Amenidades e fornecimento',
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _cafe,
                            items: _cafes
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _cafe = v ?? 'Sem café'),
                            decoration: const InputDecoration(
                              labelText: 'Tipo de café',
                              prefixIcon: Icon(Icons.coffee),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _fornecedorRoupa,
                            items: _fornecedores
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _fornecedorRoupa = v ?? 'Loja'),
                            decoration: const InputDecoration(
                              labelText: 'Fornecedor de roupa',
                              prefixIcon: Icon(Icons.local_laundry_service),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Helpers de UI ----------

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _qtyRow(
    String label,
    int value,
    IconData icon,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          IconButton(
            tooltip: 'Diminuir',
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 36,
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Aumentar',
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  void _aplicarSugestaoRoupas() {
    int sFronha = 2,
        sLencolCasal = 1,
        sCapaCasal = 1,
        sLencolSolt = 0,
        sCapaSolt = 0;
    int sBanho = 2,
        sRosto = 2,
        sTapete = (_banhos > 0 ? _banhos : 1),
        sPano = 1;

    switch (_tipologia) {
      case 'T0':
        sBanho = 1;
        sRosto = 1;
        sTapete = (_banhos > 0 ? _banhos : 1);
        break;
      case 'T1':
        break;
      case 'T2':
        sFronha = 4;
        sLencolCasal = 2;
        sCapaCasal = 2;
        sBanho = 4;
        sRosto = 4;
        sTapete = (_banhos > 0 ? _banhos : 2);
        break;
      default:
        final n = int.tryParse(_tipologia.replaceAll('T', '')) ?? 1;
        sFronha = 2 * n;
        sLencolCasal = n;
        sCapaCasal = n;
        sBanho = 2 * n;
        sRosto = 2 * n;
        sTapete = (_banhos > 0 ? _banhos : n.clamp(1, 9));
        break;
    }

    setState(() {
      _qFronha = sFronha;
      _qLencolCasal = sLencolCasal;
      _qCapaCasal = sCapaCasal;
      _qLencolSolteiro = sLencolSolt;
      _qCapaSolteiro = sCapaSolt;
      _qToalhaBanho = sBanho;
      _qToalhaRosto = sRosto;
      _qTapete = sTapete;
      _qPanoLimpeza = sPano;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final enderecoCompleto = _montarEnderecoCompleto();

    final data = {
      'nome': _nome.text.trim(),
      'enderecoRua': _rua.text.trim(),
      'enderecoNumero': _numero.text.trim(),
      'enderecoComplemento': _complemento.text.trim(),
      'enderecoBairro': _bairro.text.trim(),
      'cidade': _cidade.text.trim(),
      'distrito': _distrito.text.trim(),
      'pais': _pais.text.trim(),
      'codigoPostal': _codigoPostal.text.trim(),
      'endereco': enderecoCompleto,

      'tipologia': _tipologia,
      'banhos': _banhos,
      'sofaCama': _sofaCama,

      'cafe': _cafe == 'Sem café' ? null : _cafe,

      'levarChave': _levarChave,
      'codigoPredio': _codigoPredio.text.trim().isEmpty
          ? null
          : _codigoPredio.text.trim(),
      'codigoApartamento': _codigoApartamento.text.trim().isEmpty
          ? null
          : _codigoApartamento.text.trim(),
      'temLockbox': _temLockbox,
      'lockboxCodigo': _temLockbox && _lockboxCodigo.text.trim().isNotEmpty
          ? _lockboxCodigo.text.trim()
          : null,
      'lockboxLocal': _temLockbox && _lockboxLocal.text.trim().isNotEmpty
          ? _lockboxLocal.text.trim()
          : null,

      'fornecedorRoupa': _fornecedorRoupa,

      'roupa': {
        'fronha': _qFronha,
        'lençol_casal': _qLencolCasal,
        'capa_casal': _qCapaCasal,
        'lençol_solteiro': _qLencolSolteiro,
        'capa_solteiro': _qCapaSolteiro,
        'toalha_banho': _qToalhaBanho,
        'toalha_rosto': _qToalhaRosto,
        'tapete': _qTapete,
        'pano_limpeza': _qPanoLimpeza,
      },

      'fotos': (widget.propriedade?.get('fotos') as List?) ?? [],
    };

    try {
      final empresaId = Provider.of<AppState>(
        context,
        listen: false,
      ).empresaId!;
      final propriedadesRef = FirebaseFirestore.instance
          .collection('empresas')
          .doc(empresaId)
          .collection('propriedades');
      if (widget.propriedade == null) {
        await propriedadesRef.add(data);
      } else {
        await propriedadesRef.doc(widget.propriedade!.id).update(data);
      }
      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _montarEnderecoCompleto() {
    final parts = <String>[
      _rua.text.trim(),
      _numero.text.trim().isEmpty ? '' : _numero.text.trim(),
      _complemento.text.trim().isEmpty ? '' : _complemento.text.trim(),
      _bairro.text.trim().isEmpty ? '' : _bairro.text.trim(),
      _cidade.text.trim(),
      _distrito.text.trim().isEmpty ? '' : _distrito.text.trim(),
      _codigoPostal.text.trim().isEmpty ? '' : _codigoPostal.text.trim(),
      _pais.text.trim(),
    ].where((e) => e.isNotEmpty).toList();
    return parts.join(', ');
  }
}

// Mascarador de código postal PT "NNNN-NNN"
class _CodigoPostalPtFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 7) text = text.substring(0, 7);
    String formatted = text;
    if (text.length > 4) {
      formatted = '${text.substring(0, 4)}-${text.substring(4)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
