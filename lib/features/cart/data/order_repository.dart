import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chad_book_store/features/cart/domain/cart_item.dart';
import 'package:chad_book_store/features/cart/domain/order.dart';
import 'package:chad_book_store/features/products/domain/book.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(Supabase.instance.client);
});

class OrderRepository {
  final SupabaseClient _client;

  OrderRepository(this._client);

  Future<void> placeOrder({required List<CartItem> items}) async {
    if (_client.auth.currentUser == null) {
      throw StateError('Connectez-vous pour passer une commande.');
    }
    if (items.isEmpty) {
      throw StateError('Le panier est vide.');
    }

    await _client.rpc(
      'place_order',
      params: {
        'p_items': items
            .map((item) => {'book_id': item.book.id, 'quantity': item.quantity})
            .toList(),
      },
    );
  }

  Future<List<Order>> getMyOrders() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Connectez-vous pour voir vos commandes.');
    }

    final response = await _client
        .from('orders')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => Order.fromJson(json))
        .toList();
  }

  Future<List<Book>> getMyBooks() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Connectez-vous pour accéder à votre bibliothèque.');
    }

    late final List<dynamic> response;
    try {
      response = await _client
          .from('orders')
          .select('book_ids')
          .eq('user_id', user.id);
    } on PostgrestException catch (error) {
      if (error.code == '42703' && error.message.contains('orders.book_ids')) {
        throw const LibrarySetupRequiredException();
      }
      rethrow;
    }

    final bookIds = <String>{};
    for (final order in response) {
      final ids = (order as Map<String, dynamic>)['book_ids'];
      if (ids is List) {
        bookIds.addAll(ids.map((id) => id.toString()));
      }
    }

    if (bookIds.isEmpty) return [];

    final books = await _client
        .from('books')
        .select()
        .inFilter('id', bookIds.toList())
        .order('title', ascending: true);
    return (books as List<dynamic>).map((json) => Book.fromJson(json)).toList();
  }

  Future<String> getReadingUrl(String bookId) async {
    final books = await getMyBooks();
    Book? ownedBook;
    for (final book in books) {
      if (book.id == bookId) {
        ownedBook = book;
        break;
      }
    }

    if (ownedBook == null) {
      throw StateError('Ce livre ne figure pas dans vos commandes.');
    }
    final path = ownedBook.readingPath;
    if (path == null || path.isEmpty) {
      throw StateError(
        'Le fichier de lecture de ce livre n’est pas disponible.',
      );
    }
    return _client.storage.from('book-files').createSignedUrl(path, 60 * 60);
  }
}

class LibrarySetupRequiredException implements Exception {
  const LibrarySetupRequiredException();

  @override
  String toString() =>
      'La bibliothèque n’est pas configurée sur Supabase. Dans le SQL Editor '
      'de votre projet, exécutez le fichier '
      'supabase/migrations/20261123160000_restore_user_features.sql, puis '
      'réessayez.';
}
