import 'package:chad_book_store/features/favorites/data/favorites_repository.dart';
import 'package:chad_book_store/features/products/data/products_repository.dart';
import 'package:chad_book_store/features/products/domain/book.dart';
import 'package:chad_book_store/features/products/presentation/widgets/book_card.dart';
import 'package:chad_book_store/core/widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final favoriteBooksProvider = FutureProvider.autoDispose<List<Book>>((
  ref,
) async {
  final ids = await ref.watch(favoriteBookIdsProvider.future);
  return ref.watch(productsRepositoryProvider).getBooksByIds(ids);
});

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(favoriteBooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 2),
      body: books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Aucun livre dans vos favoris.'));
          }
          final width = MediaQuery.sizeOf(context).width;
          final columns = width >= 1000
              ? 4
              : width >= 650
              ? 3
              : 2;
          final inset = width >= 1100
              ? (width - 1000) / 2
              : width >= 650
              ? 40.0
              : 16.0;
          return GridView.builder(
            padding: EdgeInsets.all(inset),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: columns == 2 ? 0.57 : 0.66,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final book = items[index];
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
