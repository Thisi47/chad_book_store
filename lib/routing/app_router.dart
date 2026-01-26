import 'package:go_router/go_router.dart';
import 'package:chad_book_store/features/auth/presentation/pages/login_page.dart';

// On définit le routeur comme une variable globale pour l'instant
final appRouter = GoRouter(
  routes: [
    // Route racine : redirige vers le login pour l'instant
    GoRoute(
      path: '/', 
      redirect: (context, state) => '/login',
    ),
    
    GoRoute(
      path: "/login",
      builder: (context, state) => const LoginPage(),
    )
  ]
);