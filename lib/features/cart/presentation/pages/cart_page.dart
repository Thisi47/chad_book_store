import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; // Import Hook
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Import HookConsumer
import 'package:go_router/go_router.dart';
import 'package:chad_book_store/features/cart/presentation/cart_provider.dart';
import 'package:chad_book_store/features/cart/presentation/widgets/cart_item_widget.dart';
import 'package:chad_book_store/features/cart/data/order_repository.dart'; // Import Repo

// Changement ici : HookConsumerWidget
class CartPage extends HookConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    // État local pour le chargement du bouton
    final isOrdering = useState(false);

    // Fonction de commande
    Future<void> _submitOrder() async {
      isOrdering.value = true; // Début chargement
      try {
        // 1. Envoi à Supabase
        await ref.read(orderRepositoryProvider).placeOrder(totalAmount: total);

        // 2. Vider le panier local
        ref.read(cartProvider.notifier).clearCart();

        if (context.mounted) {
          // 3. Dialogue de succès
          showDialog(
            context: context,
            barrierDismissible: false, // Oblige à cliquer sur OK
            builder: (ctx) => AlertDialog(
              title: const Text("Félicitations ! 🎉"),
              content: const Text("Votre commande a été enregistrée avec succès."),
              actions: [
                TextButton(
                  onPressed: () {
                    context.pop(); // Ferme dialogue
                    context.pop(); // Ferme page panier (Retour accueil)
                  },
                  child: const Text("OK"),
                )
              ],
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: ${e.toString()}")),
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
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref.read(cartProvider.notifier).clearCart(),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text("Votre panier est vide", style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text("Commencer mes achats"),
            )
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) => CartItemWidget(item: cartItems[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("$total FCFA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // BOUTON COMMANDER CONNECTÉ
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isOrdering.value ? null : _submitOrder, // Désactivé si chargement
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: isOrdering.value
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Commander", style: TextStyle(fontSize: 18)),
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