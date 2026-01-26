import 'package:chad_book_store/features/products/presentation/pages/home_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:chad_book_store/features/auth/presentation/pages/login_page.dart';
import 'package:chad_book_store/features/auth/data/auth_state_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


// On définit le routeur comme une variable globale pour l'instant
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    debugLogDiagnostics: true,
    initialLocation: '/login',

    routes: [
      GoRoute(
        path: "/login",
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage()
      )
  ],

  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isGoingToLogin = state.uri.toString() == "/login";  

    if(!isLoggedIn && !isGoingToLogin) {
      return "/login";
    }

    if(isLoggedIn && isGoingToLogin) return '/home';

    return null;
  }
  );


}
);