import 'package:chad_book_store/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:chad_book_store/features/products/domain/book.dart';
import 'package:flutter/material.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.onTap});
  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Hero(
                    tag: 'book-cover-${book.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: book.coverUrl == null
                          ? ColoredBox(
                              color: colors.surfaceContainerHighest,
                              child: Icon(
                                Icons.auto_stories_rounded,
                                size: 42,
                                color: colors.primary,
                              ),
                            )
                          : Image.network(
                              book.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color: colors.surfaceContainerHighest,
                                child: Icon(
                                  Icons.auto_stories_rounded,
                                  size: 42,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: .94),
                      shape: BoxShape.circle,
                    ),
                    child: FavoriteButton(bookId: book.id),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            '${book.price} FCFA',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
