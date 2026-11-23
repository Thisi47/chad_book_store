import 'package:chad_book_store/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

class AuthRepository {
  final SupabaseClient _supabase;
  AuthRepository(this._supabase);

  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> signInWithGoogle() {
    return _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConstants.authRedirectUrl,
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: AppConstants.authRedirectUrl,
    );
  }

  Future<void> updatePassword({required String password}) async {
    await _supabase.auth.updateUser(UserAttributes(password: password));
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: AppConstants.authRedirectUrl,
    );
  }

  Future<void> resendSignupConfirmation({required String email}) async {
    await _supabase.auth.resend(
      email: email,
      type: OtpType.signup,
      emailRedirectTo: AppConstants.authRedirectUrl,
    );
  }

  // Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Vérifier si un utilisateur est déjà connecté
  User? get currentUser => _supabase.auth.currentUser;
}
