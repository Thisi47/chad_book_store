import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(Supabase.instance.client);
});

class OrderRepository {
  final SupabaseClient _client;

  OrderRepository(this._client);

  Future<void> placeOrder({required int totalAmount}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    try {
      // Insertion simple
      await _client.from('orders').insert({
        'user_id': user.id,
        'total_price': totalAmount,
        'status': 'en_attente',
      });
    } catch (e) {
      throw Exception("Erreur lors de la commande : $e");
    }
  }
}