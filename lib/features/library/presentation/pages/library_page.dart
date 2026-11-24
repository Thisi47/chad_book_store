import 'package:chad_book_store/features/cart/data/order_repository.dart';
import 'package:chad_book_store/core/widgets/cached_book_image.dart';
import 'package:chad_book_store/core/widgets/empty_state.dart';
import 'package:chad_book_store/features/products/domain/book.dart';
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
      body: books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Bibliothèque indisponible',
          message: error is LibrarySetupRequiredException
              ? error.toString()
              : 'Vérifiez votre connexion puis réessayez.',
          actionLabel: 'Réessayer',
          onAction: () => ref.invalidate(myBooksProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_rounded,
              title: 'Votre bibliothèque est vide',
              message: 'Les livres disponibles à la lecture apparaîtront ici.',
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
              : CachedBookImage(url: book.coverUrl!, cacheWidth: 120),
        ),
        title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (book.readingPath == null)
              Text(
                'Fichier de lecture à configurer',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: IconButton.filled(
          tooltip: book.readingPath == null
              ? 'Détails de disponibilité'
              : 'Lire le livre',
          onPressed: () {
            if (book.readingPath != null) {
              context.push('/reader', extra: book);
              return;
            }
            showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                icon: const Icon(Icons.menu_book_outlined),
                title: const Text('Fichier non configuré'),
                content: Text(
                  'Le livre « ${book.title} » est dans votre bibliothèque, '
                  'mais son document n’est pas encore relié. Un fichier PDF, '
                  'EPUB, TXT ou Markdown doit être ajouté au stockage privé '
                  '« book-files » et son chemin enregistré dans reading_path.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Compris'),
                  ),
                ],
              ),
            );
          },
          icon: Icon(
            book.readingPath == null
                ? Icons.info_outline_rounded
                : Icons.menu_book,
          ),
        ),
      ),
    );
  }
}
