import 'package:flutter/material.dart';

class TarefaInfoCard extends StatelessWidget {
  final Map<String, dynamic>? propriedadeData;
  final VoidCallback onAddressTap;
  final String tipoTarefa;

  const TarefaInfoCard({
    super.key,
    required this.propriedadeData,
    required this.onAddressTap,
    required this.tipoTarefa,
  });

  @override
  Widget build(BuildContext context) {
    if (propriedadeData == null) return const SizedBox.shrink();

    return Column(
      children: [
        _addressCard(context, propriedadeData!['endereco'] ?? '', onAddressTap),
        _sectionCard(
          context,
          icon: Icons.vpn_key,
          title: 'Acessos',
          children: [
            if (propriedadeData!['levarChave'] == true)
              _tile(icon: Icons.key, title: 'Levar chave', subtitle: 'Sim'),
            if ((propriedadeData!['codigoPredio'] ?? '').toString().isNotEmpty)
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
            ],
          ],
        ),
      ],
    );
  }

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
}
