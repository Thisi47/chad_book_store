import 'dart:async';
import 'dart:convert';

import 'package:chad_book_store/features/products/domain/book.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(Supabase.instance.client);
});

class ProductsRepository {
  ProductsRepository(this._client);

  static const _catalogKey = 'catalog_cache_v1';
  static const _freshFor = Duration(minutes: 10);

  final SupabaseClient _client;
  List<Book>? _catalog;
  final Map<String, Book> _bookDetails = {};
  DateTime? _catalogSavedAt;
  Future<List<Book>>? _refreshInFlight;

  /// Returns a local snapshot immediately when one exists and refreshes it
  /// quietly when it is old. This keeps a slow or unavailable connection from
  /// blocking the catalogue on every app launch.
  Future<List<Book>> getAllBooks() async {
    final now = DateTime.now();
    if (_catalog != null &&
        now.difference(_catalogSavedAt ?? now) < _freshFor) {
      return _catalog!;
    }

    if (_catalog == null) {
      final cached = await _readCatalogCache();
      if (cached != null) {
        _catalog = cached.books;
        _catalogSavedAt = cached.savedAt;
      }
    }

    if (_catalog != null) {
      if (now.difference(
            _catalogSavedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ) >=
          _freshFor) {
        unawaited(_refreshCatalog());
      }
      return _catalog!;
    }

    return _refreshCatalog();
  }

  Future<List<Book>> _refreshCatalog() async {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final request = _fetchAndCacheCatalog();
    _refreshInFlight = request;
    try {
      return await request;
    } catch (_) {
      if (_catalog != null) return _catalog!;
      rethrow;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<List<Book>> _fetchAndCacheCatalog() async {
    final response = await _client
        .from('books')
        .select('id,title,author,price,cover_url,category')
        .order('title', ascending: true);
    final books = (response as List<dynamic>)
        .map((json) => Book.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);

    _catalog = books;
    _catalogSavedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _catalogKey,
      jsonEncode({
        'saved_at': _catalogSavedAt!.millisecondsSinceEpoch,
        'books': books.map(_toCacheJson).toList(growable: false),
      }),
    );
    return books;
  }

  Future<_CatalogSnapshot?> _readCatalogCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_catalogKey);
      if (value == null) return null;
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        decoded['saved_at'] as int,
      );
      final rows = decoded['books'] as List<dynamic>;
      final books = rows
          .map((row) => Book.fromJson(row as Map<String, dynamic>))
          .toList(growable: false);
      return _CatalogSnapshot(books: books, savedAt: savedAt);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toCacheJson(Book book) => {
    'id': book.id,
    'title': book.title,
    'author': book.author,
    'price': book.price,
    'cover_url': book.coverUrl,
    'category': book.category,
  };

  Future<Book> getBookDetails(String id) async {
    final cached = _bookDetails[id];
    if (cached != null) return cached;

    final response = await _client
        .from('books')
        .select('id,title,author,price,cover_url,description,category')
        .eq('id', id)
        .single();
    final book = Book.fromJson(response);
    _bookDetails[id] = book;
    return book;
  }

  Future<List<Book>> getBooksByIds(Iterable<String> ids) async {
    final bookIds = ids.toSet().toList(growable: false);
    if (bookIds.isEmpty) return [];

    final cachedBooks = _catalog;
    if (cachedBooks != null) {
      final byId = {for (final book in cachedBooks) book.id: book};
      if (bookIds.every(byId.containsKey)) {
        final books = bookIds.map((id) => byId[id]!).toList();
        books.sort((a, b) => a.title.compareTo(b.title));
        return books;
      }
    }

    final response = await _client
        .from('books')
        .select('id,title,author,price,cover_url,category')
        .inFilter('id', bookIds)
        .order('title', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Book.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }
}

class _CatalogSnapshot {
  const _CatalogSnapshot({required this.books, required this.savedAt});

  final List<Book> books;
  final DateTime savedAt;
}
