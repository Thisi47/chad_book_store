import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chad_book_store/features/cart/domain/cart_item.dart';
import 'package:chad_book_store/features/cart/presentation/cart_provider.dart';

class CartItemWidget extends ConsumerWidget {
  final CartItem item;

  const CartItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // 1. Image Miniature (Avec gestion d'erreur robuste)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox( // On force une taille fixe quoiqu'il arrive
                width: 60,
                height: 80,
                child: item.book.coverUrl != null
                    ? Image.network(
                  item.book.coverUrl!,
                  fit: BoxFit.cover,
                  // C'est ici qu'on gère l'erreur 403/404 pour ne pas casser le layout
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.book, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 2. Infos Livre (Expanded est CRUCIAL pour éviter l'overflow)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis, // Coupe le texte s'il est trop long
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove,
                  onTap: () {
                    ref.read(cartProvider.notifier).removeItem(item.book);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8), // Réduit un peu l'espace
                  child: Text(
                    "${item.quantity}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  onTap: () {
                    ref.read(cartProvider.notifier).addItem(item.book);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }
}