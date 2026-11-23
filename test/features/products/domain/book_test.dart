import 'package:chad_book_store/features/products/domain/book.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Book.fromJson reads the private ebook path when available', () {
    final book = Book.fromJson({
      'id': 42,
      'title': 'Livre',
      'author': 'Auteur',
      'price': 1200,
      'reading_path': '42/book.pdf',
    });

    expect(book.id, '42');
    expect(book.readingPath, '42/book.pdf');
  });

  test('Book.fromJson supports catalog rows without ebook metadata', () {
    final book = Book.fromJson({
      'id': 'book-1',
      'title': 'Livre',
      'author': 'Auteur',
      'price': 1200,
    });

    expect(book.readingPath, isNull);
  });
}
