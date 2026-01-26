import 'package:chad_book_store/features/products/domain/book.dart';

class CartItem {
  final Book book;
  final int quantity;

  const CartItem({
    required this.book,
    this.quantity = 1
  });

  CartItem copyWith({ int? quantity }) {
    return CartItem(book: book, quantity: quantity ?? this.quantity);
  }

  // Calcul du prix total de cet article (Prix * Quantité)
  int get totalPrice => book.price * quantity;

}