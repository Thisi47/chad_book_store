import 'package:chad_book_store/features/auth/data/auth_repository.dart';
import 'package:chad_book_store/features/cart/presentation/cart_provider.dart';
import 'package:chad_book_store/features/products/data/products_repository.dart';
import 'package:chad_book_store/features/products/domain/book.dart';
import 'package:chad_book_store/features/products/presentation/widgets/book_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On récupère le repository
    final productsRepo = ref.watch(productsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chad Book Store"),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final cartItems = ref.watch(cartProvider);
              final count = cartItems.length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      context.push('/cart');
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      // FutureBuilder : La façon la plus simple de charger une donnée unique au démarrage
      body: FutureBuilder<List<Book>>(
        future: productsRepo.getAllBooks(),
        builder: (context, snapshot) {
          // 1. Chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Erreur
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }

          // 3. Données vides
          final books = snapshot.data;
          if (books == null || books.isEmpty) {
            return const Center(child: Text("Aucun livre disponible."));
          }

          // 4. Succès : Liste des livres
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 Livres par ligne
              childAspectRatio: 0.65, // Ratio Hauteur/Largeur (Format Livre)
              crossAxisSpacing: 16, // Espace horizontal
              mainAxisSpacing: 16, // Espace vertical
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return BookCard(
                book: book,
                onTap: () => context.push('/details', extra: book),
              );
            },
          );
        },
      ),
    );
  }
}
