import 'dart:io';
import 'package:flutter/material.dart';

class TarefaFotosSection extends StatelessWidget {
  final String status;
  final bool isAtribuido;
  final List<String> taskPhotos;
  final List<File> localTaskPhotos;
  final VoidCallback onAddPhoto;
  final Function(int) onOpenGallery;
  final Function(String) onDeletePhoto;

  const TarefaFotosSection({
    super.key,
    required this.status,
    required this.isAtribuido,
    required this.taskPhotos,
    required this.localTaskPhotos,
    required this.onAddPhoto,
    required this.onOpenGallery,
    required this.onDeletePhoto,
  });

  @override
  Widget build(BuildContext context) {
    if (status != 'em_andamento' &&
        status != 'reaberta' &&
        status != 'concluida') {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final canEdit =
        (status == 'em_andamento' || status == 'reaberta') && isAtribuido;

    // Calculando largura para caber 3 colunas (ajustável)
    final width = MediaQuery.of(context).size.width;
    // (largura total - paddings laterais) / 3 colunas
    final itemSize = (width - 36 - 20) / 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            "Fotos da Tarefa",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Botão de Adicionar (Câmera) - Só aparece se puder editar
            if (canEdit)
              GestureDetector(
                onTap: onAddPhoto,
                child: Container(
                  width: itemSize,
                  height: itemSize,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary, width: 1.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: cs.primary, size: 32),
                        const SizedBox(height: 4),
                        Text(
                          "Adicionar",
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Fotos Locais (Carregando...)
            ...localTaskPhotos.map((f) => _buildLocalPhoto(f, itemSize)),

            // Fotos Remotas (Já salvas)
            ...taskPhotos.asMap().entries.map((entry) {
              return _buildRemotePhoto(
                context,
                entry.key,
                entry.value,
                canEdit,
                itemSize,
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildLocalPhoto(File f, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(f, width: size, height: size, fit: BoxFit.cover),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.3),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemotePhoto(
    BuildContext context,
    int index,
    String url,
    bool canEdit,
    double size,
  ) {
    return GestureDetector(
      onTap: () => onOpenGallery(index),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Hero(
              tag: url, // Animação suave ao abrir
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (canEdit)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onDeletePhoto(url),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
