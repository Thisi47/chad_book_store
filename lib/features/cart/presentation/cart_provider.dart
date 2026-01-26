import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chad_book_store/features/cart/domain/cart_item.dart';
import 'package:chad_book_store/features/products/domain/book.dart';

// 1. Le Notifier : C'est lui qui gère la liste des articles
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]); // Au début, le panier est vide

  // Ajouter un livre
  void addItem(Book book) {
    // Est-ce que le livre est déjà dans le panier ?
    final existingIndex = state.indexWhere((item) => item.book.id == book.id);

    if (existingIndex >= 0) {
      // Oui -> On augmente juste la quantité (+1)
      final oldItem = state[existingIndex];
      final newItem = oldItem.copyWith(quantity: oldItem.quantity + 1);

      // On remplace l'ancien item par le nouveau dans la liste
      state = [
        ...state.sublist(0, existingIndex),
        newItem,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // Non -> On l'ajoute comme nouvel article
      state = [...state, CartItem(book: book)];
    }
  }

  // Retirer un livre (ou diminuer quantité)
  void removeItem(Book book) {
    final index = state.indexWhere((item) => item.book.id == book.id);
    if (index < 0) return;

    final existingItem = state[index];

    if (existingItem.quantity > 1) {
      // S'il y en a plusieurs, on diminue la quantité
      final newItem = existingItem.copyWith(
        quantity: existingItem.quantity - 1,
      );
      state = [
        ...state.sublist(0, index),
        newItem,
        ...state.sublist(index + 1),
      ];
    } else {
      // S'il n'en reste qu'un, on le supprime complètement de la liste
      state = state.where((item) => item.book.id != book.id).toList();
    }
  }

  // Vider le panier
  void clearCart() {
    state = [];
  }
}

// 2. Le Provider Global : Accessible partout dans l'app
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// 3. Un Provider spécial pour calculer le TOTAL (FCFA) automatiquement
final cartTotalProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  // On additionne le prix de chaque item
  return cart.fold(0, (sum, item) => sum + item.totalPrice);
});
