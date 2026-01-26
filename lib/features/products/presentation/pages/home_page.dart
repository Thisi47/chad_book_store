import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chad_book_store/features/auth/data/auth_repository.dart';

class HomePage extends ConsumerWidget{
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Librairie Tchad Books"),
        actions: [
          // Bouton de déconnexion
          IconButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();

              if(context.mounted) {
                context.go('/login');
              }
            }, 
          icon: Icon(Icons.logout)
          )
        ],
      ),

      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey,),
            SizedBox(height: 20,),
            Text("Catalogue vide pour l'instance !")
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Future action : Ajouter un livre (admin) ou paniel
        },
        child: Icon(Icons.add),
      ),
    );
  }
}