import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

class AuthRepository {
  final SupabaseClient _supabase;
  AuthRepository(this._supabase);

  // Fonction de connexion
  Future<void> signIn({required String email, required String password }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,  
        password : password
      );
    } catch(e) {
      throw Exception("Erreur de connexion : $e");
    }
  }

  // Fonction d'inscription (pour plus tard)
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password
      );
    } catch (e) {
      throw Exception("Erreur d'inscription : $e");
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Vérifier si un utilisateur est déjà connecté
  User? get currentUser => _supabase.auth.currentUser;
}