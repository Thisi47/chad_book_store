import 'package:chad_book_store/features/cart/data/order_repository.dart';
import 'package:chad_book_store/features/products/domain/book.dart';
import 'package:chad_book_store/core/widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final myBooksProvider = FutureProvider.autoDispose<List<Book>>((ref) {
  return ref.watch(orderRepositoryProvider).getMyBooks();
});

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(myBooksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ma bibliothèque')),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 1),
      body: books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  error is LibrarySetupRequiredException
                      ? error.toString()
                      : 'Impossible de charger votre bibliothèque : $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => ref.invalidate(myBooksProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Les livres commandés apparaîtront ici.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _LibraryBookTile(book: items[index]),
          );
        },
      ),
    );
  }
}

class _LibraryBookTile extends StatelessWidget {
  const _LibraryBookTile({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: SizedBox(
          width: 52,
          child: book.coverUrl == null
              ? const Icon(Icons.book, size: 36)
              : Image.network(
                  book.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.book, size: 36),
                ),
        ),
        title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          book.readingPath == null ? 'Lecture indisponible' : book.author,
        ),
        trailing: IconButton.filled(
          tooltip: 'Lire le livre',
          onPressed: book.readingPath == null
              ? null
              : () => context.push('/reader', extra: book),
          icon: const Icon(Icons.menu_book),
        ),
      ),
    );
  }
}
