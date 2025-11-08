import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  String _cafe = 'Delta Q';

  // Acesso
  bool _levarChave = true;
  late TextEditingController _codigoPredio, _codigoApartamento;
  bool _temLockbox = false;
  late TextEditingController _lockboxLocal, _lockboxCodigo;

  // Fornecedor
  String _fornecedorRoupa = 'Loja';

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
    _banhos = (data['banhos'] is int) ? (data['banhos'] as int) : 1;
    _sofaCama = data['sofaCama'] == true;
    _cafe = (data['cafe'] ?? 'Delta Q').toString();

    _levarChave = data['levarChave'] != false;
    _codigoPredio = TextEditingController(text: data['codigoPredio'] ?? '');
    _codigoApartamento = TextEditingController(
      text: data['codigoApartamento'] ?? '',
    );

    _temLockbox = data['temLockbox'] == true;
    _lockboxLocal = TextEditingController(text: data['lockboxLocal'] ?? '');
    _lockboxCodigo = TextEditingController(text: data['lockboxCodigo'] ?? '');

    _fornecedorRoupa = (data['fornecedorRoupa'] ?? 'Loja').toString();
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
  List<String> get _cafes => const ['Delta Q', 'Nespresso', 'Dolce Gusto'];
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
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Propriedade' : 'Nova Propriedade'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Identificação
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(
                labelText: 'Nome da propriedade *',
                prefixIcon: Icon(Icons.home),
              ),
              validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            Text('Endereço', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _rua,
              decoration: const InputDecoration(
                labelText: 'Rua *',
                prefixIcon: Icon(Icons.signpost),
              ),
              validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
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
                    validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
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
                    validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
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
                      return re.hasMatch(s) ? null : 'Formato: NNNN-NNN';
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tipologia, banhos, sofá-cama
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _tipologia,
                    items: _tipologias
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _tipologia = v ?? 'T1'),
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
                          (b) => DropdownMenuItem(value: b, child: Text('$b')),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _banhos = v ?? 1),
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
            ),
            const SizedBox(height: 16),

            // Café
            DropdownButtonFormField<String>(
              initialValue: _cafe,
              items: _cafes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _cafe = v ?? 'Delta Q'),
              decoration: const InputDecoration(
                labelText: 'Tipo de café',
                prefixIcon: Icon(Icons.coffee),
              ),
            ),
            const SizedBox(height: 16),

            // Acessos
            CheckboxListTile(
              title: const Text('Levar chave'),
              value: _levarChave,
              onChanged: (v) => setState(() => _levarChave = v ?? false),
              secondary: const Icon(Icons.vpn_key),
              controlAffinity: ListTileControlAffinity.leading,
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
              onChanged: (v) => setState(() => _temLockbox = v ?? false),
              secondary: const Icon(Icons.lock_outline),
              controlAffinity: ListTileControlAffinity.leading,
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
            const SizedBox(height: 16),

            // Fornecedor de roupa
            DropdownButtonFormField<String>(
              initialValue: _fornecedorRoupa,
              items: _fornecedores
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _fornecedorRoupa = v ?? 'Loja'),
              decoration: const InputDecoration(
                labelText: 'Fornecedor de roupa',
                prefixIcon: Icon(Icons.local_laundry_service),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(widget.propriedade == null ? 'Adicionar' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
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

      'cafe': _cafe,

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

      'fotos': (widget.propriedade?.get('fotos') as List?) ?? [],
    };

    try {
      if (widget.propriedade == null) {
        await FirebaseFirestore.instance
            .collection('propertask')
            .doc('propriedades')
            .collection('propriedades')
            .add(data);
      } else {
        await widget.propriedade!.reference.update(data);
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
