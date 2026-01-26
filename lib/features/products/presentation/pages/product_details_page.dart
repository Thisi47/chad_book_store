import 'package:flutter/material.dart';
import 'package:chad_book_store/features/products/domain/book.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chad_book_store/features/cart/presentation/cart_provider.dart';
import 'package:go_router/go_router.dart';

class ProductDetailsPage extends ConsumerWidget {
  final Book book;

  const ProductDetailsPage({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white, // Fond pur
      // AppBar transparente pour laisser la place à l'image
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // Flèche retour noire
      ),
      extendBodyBehindAppBar: true, // L'image passe SOUS la barre d'état

      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Zone Image "Hero" avec fond décoratif
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100], // Fond gris très clair derrière le livre
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Center(
                child: Hero(
                  tag: 'book-cover-${book.id}', // Même tag que sur la Home Page !
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: book.coverUrl != null
                          ? Image.network(book.coverUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.book, size: 100),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Contenu textuel
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auteur et Catégorie
                  Row(
                    children: [
                      Chip(
                        label: Text(book.category ?? 'Général'),
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                        padding: EdgeInsets.zero,
                      ),
                      const Spacer(),
                      Text(
                        book.author,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Titre
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Prix
                  Text(
                    "${book.price} FCFA",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    "À propos de ce livre",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    book.description ?? "Aucune description.",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6, // Meilleure lisibilité
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            // Espace pour ne pas être caché par le bouton flottant s'il y en a un
            const SizedBox(height: 100),
          ],
        ),
      ),

      // 3. Barre d'action fixe en bas (Sticky Bottom Bar)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: FilledButton(
            // ACTION DU BOUTON
            onPressed: () {
              // 1. Ajouter au panier via Riverpod
              ref.read(cartProvider.notifier).addItem(book);

              // 2. Feedback visuel (SnackBar)
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${book.title} ajouté au panier !"),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'VOIR PANIER',
                    onPressed: () {
                      // TODO: Naviguer vers la page panier (étape suivante)
                    },
                  ),
                ),
              );

              // Optionnel : Retourner en arrière automatiquement
              context.pop();
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFF00695C), // Vert Tchad Books
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined),
                SizedBox(width: 10),
                Text("Ajouter au panier", style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}