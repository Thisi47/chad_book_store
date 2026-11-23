import 'package:chad_book_store/features/cart/domain/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Order.fromJson parses the purchased book IDs', () {
    final order = Order.fromJson({
      'id': 7,
      'total_price': 2400.0,
      'status': 'en_attente',
      'created_at': '2026-11-23T12:00:00Z',
      'book_ids': [42, 'book-2'],
    });

    expect(order.id, '7');
    expect(order.totalPrice, 2400);
    expect(order.bookIds, ['42', 'book-2']);
  });
}
