import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chad_book_store/features/cart/domain/order.dart'; // Import du modèle

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(Supabase.instance.client);
});

class OrderRepository {
  final SupabaseClient _client;

  OrderRepository(this._client);

  // 1. Passer commande (Déjà fait)
  Future<void> placeOrder({required int totalAmount}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    try {
      await _client.from('orders').insert({
        'user_id': user.id,
        'total_price': totalAmount,
        'status': 'en_attente',
      });
    } catch (e) {
      throw Exception("Erreur commande : $e");
    }
  }

  // 2. Récupérer l'historique (NOUVEAU)
  Future<List<Order>> getMyOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .order('created_at', ascending: false); // Les plus récentes en haut

      final data = response as List<dynamic>;
      return data.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception("Erreur historique : $e");
    }
  }
}