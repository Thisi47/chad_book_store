import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chad_book_store/features/products/domain/book.dart';

// Provider simple pour accéder au repo
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(Supabase.instance.client);
});

class ProductsRepository {
  final SupabaseClient _client;

  ProductsRepository(this._client);

  // Récupérer tous les livres
  Future<List<Book>> getAllBooks() async {
    try {
      // 1. On demande la table 'books', on sélectionne tout, ordonné par titre
      final response = await _client
          .from('books')
          .select()
          .order('title', ascending: true);

      // 2. Supabase renvoie une List<dynamic> (JSON)
      final data = response as List<dynamic>;

      // 3. On convertit chaque JSON en objet Book grâce à Freezed
      return data.map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement livres: $e');
    }
  }

  Future<List<Book>> getBooksByIds(Iterable<String> ids) async {
    final bookIds = ids.toSet().toList();
    if (bookIds.isEmpty) return [];

    final response = await _client
        .from('books')
        .select()
        .inFilter('id', bookIds)
        .order('title', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Book.fromJson(json))
        .toList();
  }
}
