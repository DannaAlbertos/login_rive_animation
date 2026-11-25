import 'package:flutter/material.dart';

import '../models/dress.dart';
import '../services/dress_service.dart';
import '../theme.dart';

/// Imagen del vestido con placeholder si no hay foto o falla la carga.
class DressImage extends StatelessWidget {
  final Dress dress;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  const DressImage({
    super.key,
    required this.dress,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final url = DressService.resolveImage(dress.imageUrl);
    final placeholder = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pinkSoft, Color(0xFFF7C6DD)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.checkroom_rounded, size: 56, color: AppColors.pink),
      ),
    );
    if (url.isEmpty) return placeholder;

    return Container(
      color: AppColors.pinkSoft.withOpacity(0.45),
      child: Image.network(
        url,
        fit: fit,
        alignment: alignment,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
        errorBuilder: (context, error, stack) => placeholder,
      ),
    );
  }
}

class DressCard extends StatelessWidget {
  final Dress dress;
  final VoidCallback onTap;
  const DressCard({super.key, required this.dress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: AppColors.pink.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.pink.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: DressImage(
                        dress: dress,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _Badge(
                        text: dress.inStock ? 'Talla ${dress.size}' : 'Agotado',
                        color: dress.inStock ? Colors.white : Colors.black87,
                        textColor:
                            dress.inStock ? AppColors.ink : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dress.category.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: AppColors.pink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dress.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${dress.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Stock: ${dress.stock}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _Badge(
      {required this.text, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}