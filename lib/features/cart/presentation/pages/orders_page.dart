import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chad_book_store/features/cart/data/order_repository.dart';
import 'package:chad_book_store/features/cart/domain/order.dart';
import 'package:go_router/go_router.dart';
import 'package:chad_book_store/core/widgets/empty_state.dart';

// 1. DÉFINITION DU PROVIDER (C'est ici la correction !)
// On le définit en dehors de la classe pour qu'il soit accessible
final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  // Il appelle le repository pour récupérer la liste
  return ref.read(orderRepositoryProvider).getMyOrders();
});

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. UTILISATION : On "watch" la variable ordersProvider définie plus haut
    final ordersAsyncValue = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Commandes"),
        actions: [
          IconButton(
            tooltip: 'Ma bibliothèque',
            onPressed: () => context.go('/library'),
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      // 3. GESTION DES ÉTATS (Chargement / Erreur / Données)
      body: ordersAsyncValue.when(
        data: (orders) {
          if (orders.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Aucune commande pour le moment',
              message: 'Vos commandes apparaîtront ici après validation.',
              actionLabel: 'Découvrir les livres',
              onAction: () => context.go('/home'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
        // État de chargement (Rond qui tourne)
        loading: () => const Center(child: CircularProgressIndicator()),
        // État d'erreur
        error: (err, stack) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Commandes indisponibles',
          message: 'Vérifiez votre connexion puis réessayez.',
          actionLabel: 'Réessayer',
          onAction: () => ref.invalidate(ordersProvider),
        ),
      ),
    );
  }
}

// Composant visuel pour une commande (inchangé)
class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        "${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.receipt_long,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          "${order.totalPrice} FCFA",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text("Le $dateStr"),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: order.status == 'en_attente'
                ? Colors.orange[100]
                : Colors.green[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            order.status.toUpperCase(),
            style: TextStyle(
              color: order.status == 'en_attente'
                  ? Colors.orange[800]
                  : Colors.green[800],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
