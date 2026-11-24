import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; // Import Hook
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Import HookConsumer
import 'package:go_router/go_router.dart';
import 'package:chad_book_store/features/cart/presentation/cart_provider.dart';
import 'package:chad_book_store/features/cart/presentation/widgets/cart_item_widget.dart';
import 'package:chad_book_store/features/cart/data/order_repository.dart'; // Import Repo
import 'package:chad_book_store/core/widgets/app_feedback.dart';
import 'package:chad_book_store/core/widgets/empty_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Changement ici : HookConsumerWidget
class CartPage extends HookConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    // État local pour le chargement du bouton
    final isOrdering = useState(false);

    Future<void> confirmClearCart() async {
      final shouldClear = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.delete_outline_rounded),
          title: const Text('Vider le panier ?'),
          content: const Text('Tous les livres seront retirés du panier.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Garder'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Vider'),
            ),
          ],
        ),
      );
      if (shouldClear == true) ref.read(cartProvider.notifier).clearCart();
    }

    // Fonction de commande
    Future<void> submitOrder() async {
      if (Supabase.instance.client.auth.currentUser == null) {
        context.go(
          Uri(
            path: '/login',
            queryParameters: {'returnTo': '/cart'},
          ).toString(),
        );
        return;
      }
      isOrdering.value = true; // Début chargement
      try {
        // 1. Envoi à Supabase
        await ref.read(orderRepositoryProvider).placeOrder(items: cartItems);

        // 2. Vider le panier local
        ref.read(cartProvider.notifier).clearCart();

        if (context.mounted) {
          // 3. Dialogue de succès
          showDialog(
            context: context,
            barrierDismissible: false, // Oblige à cliquer sur OK
            builder: (ctx) => AlertDialog(
              scrollable: true,
              icon: Icon(
                Icons.check_circle_rounded,
                color: Theme.of(ctx).colorScheme.primary,
                size: 40,
              ),
              title: const Text("Commande confirmée"),
              content: const Text(
                "Votre commande a été enregistrée avec succès.",
                textAlign: TextAlign.center,
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/home');
                  },
                  child: const Text("Continuer mes achats"),
                ),
              ],
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          showAppMessage(
            context,
            'La commande n’a pas abouti. Vérifiez votre connexion puis réessayez.',
            isError: true,
          );
        }
      } finally {
        isOrdering.value = false; // Fin chargement
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Panier"),
        centerTitle: true,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              tooltip: 'Vider le panier',
              icon: const Icon(Icons.delete_outline),
              onPressed: confirmClearCart,
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Votre panier est vide',
              message: 'Ajoutez un livre et retrouvez-le ici.',
              actionLabel: 'Explorer les livres',
              onAction: () => context.go('/home'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) =>
                        CartItemWidget(item: cartItems[index]),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "$total FCFA",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // BOUTON COMMANDER CONNECTÉ
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isOrdering.value
                                ? null
                                : submitOrder, // Désactivé si chargement
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isOrdering.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Commander",
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
