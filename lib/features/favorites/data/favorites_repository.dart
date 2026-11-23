import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chad_book_store/features/auth/data/auth_state_provider.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(Supabase.instance.client);
});

final favoriteBookIdsProvider = FutureProvider<Set<String>>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(favoritesRepositoryProvider).getFavoriteBookIds();
});

class FavoritesRepository {
  FavoritesRepository(this._client);

  final SupabaseClient _client;

  Future<Set<String>> getFavoriteBookIds() async {
    final metadata = _client.auth.currentUser?.userMetadata;
    final value = metadata?['favorite_book_ids'];
    if (value is! List) return {};
    return value.map((id) => id.toString()).toSet();
  }

  Future<bool> toggleFavorite(String bookId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Connectez-vous pour enregistrer vos favoris.');
    }

    final ids = await getFavoriteBookIds();
    final isFavorite = ids.remove(bookId);
    if (!isFavorite) ids.add(bookId);

    await _client.auth.updateUser(
      UserAttributes(
        data: {...?user.userMetadata, 'favorite_book_ids': ids.toList()},
      ),
    );
    return !isFavorite;
  }
}
