import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chad_book_store/features/cart/domain/cart_item.dart';
import 'package:chad_book_store/features/cart/presentation/cart_provider.dart';
import 'package:chad_book_store/core/widgets/cached_book_image.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;

  const CartItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 340
              ? Column(
                  children: [
                    Row(
                      children: [
                        _BookCover(item: item, width: 48, height: 64),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.book.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.book.price} FCFA',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _QuantityControls(item: item),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    // 1. Image Miniature (Avec gestion d'erreur robuste)
                    _BookCover(item: item, width: 60, height: 80),
                    const SizedBox(width: 16),

                    // 2. Infos Livre (Expanded est CRUCIAL pour éviter l'overflow)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.book.title,
                            maxLines: 2,
                            overflow: TextOverflow
                                .ellipsis, // Coupe le texte s'il est trop long
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${item.book.price} FCFA",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Contrôles Quantité
                    _QuantityControls(item: item),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.item,
    required this.width,
    required this.height,
  });
  final CartItem item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: width,
      height: height,
      child: item.book.coverUrl == null
          ? ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.book_outlined),
            )
          : CachedBookImage(url: item.book.coverUrl!, cacheWidth: 140),
    ),
  );
}

class _QuantityControls extends ConsumerWidget {
  const _QuantityControls({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _QuantityButton(
        icon: Icons.remove,
        label: 'Retirer un exemplaire de ${item.book.title}',
        onTap: () => ref.read(cartProvider.notifier).removeItem(item.book),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          '${item.quantity}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      _QuantityButton(
        icon: Icons.add,
        label: 'Ajouter un exemplaire de ${item.book.title}',
        onTap: () => ref.read(cartProvider.notifier).addItem(item.book),
      ),
    ],
  );
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuantityButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: colors.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
