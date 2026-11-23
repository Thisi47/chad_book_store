import 'package:chad_book_store/features/favorites/data/favorites_repository.dart';
import 'package:chad_book_store/core/widgets/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteBookIdsProvider);
    final isFavorite = favorites.valueOrNull?.contains(bookId) ?? false;

    return IconButton(
      tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
      onPressed: favorites.isLoading
          ? null
          : () async {
              if (Supabase.instance.client.auth.currentUser == null) {
                context.go('/login');
                return;
              }
              try {
                await ref
                    .read(favoritesRepositoryProvider)
                    .toggleFavorite(bookId);
                ref.invalidate(favoriteBookIdsProvider);
              } catch (_) {
                if (!context.mounted) return;
                showAppMessage(
                  context,
                  'Impossible de mettre à jour vos favoris. Réessayez.',
                  isError: true,
                );
              }
            },
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : null,
      ),
    );
  }
}
