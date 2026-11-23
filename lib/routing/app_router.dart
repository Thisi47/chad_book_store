import 'package:chad_book_store/features/products/presentation/pages/home_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:chad_book_store/features/auth/presentation/pages/login_page.dart';
import 'package:chad_book_store/features/auth/presentation/pages/update_password_page.dart';
import 'package:chad_book_store/features/auth/presentation/pages/register_page.dart';
import 'package:chad_book_store/features/auth/data/auth_state_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chad_book_store/features/products/domain/book.dart';
import 'package:chad_book_store/features/products/presentation/pages/product_details_page.dart';
import 'package:chad_book_store/features/cart/presentation/pages/cart_page.dart';
import 'package:chad_book_store/features/favorites/presentation/pages/favorites_page.dart';
import 'package:chad_book_store/features/library/presentation/pages/library_page.dart';
import 'package:chad_book_store/features/library/presentation/pages/reader_page.dart';
import 'package:chad_book_store/features/profile/presentation/pages/profile_page.dart';

import '../features/cart/presentation/pages/orders_page.dart';

// On définit le routeur comme une variable globale pour l'instant
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    debugLogDiagnostics: true,
    initialLocation: '/home',

    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(
        path: "/login",
        builder: (context, state) => LoginPage(
          authErrorCode: state.uri.queryParameters['authError'],
          returnTo: state.uri.queryParameters['returnTo'],
        ),
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) =>
            RegisterPage(returnTo: state.uri.queryParameters['returnTo']),
      ),

      GoRoute(
        path: '/login-callback',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),

      GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordPage(),
      ),

      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryPage(),
      ),
      GoRoute(
        path: '/reader',
        builder: (context, state) {
          final book = state.extra;
          if (book is! Book) {
            return const Scaffold(
              body: Center(child: Text('Livre introuvable.')),
            );
          }
          return ReaderPage(book: book);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),

      GoRoute(
        path: '/details',
        builder: (context, state) {
          final book = state.extra;
          if (book is! Book) {
            return const Scaffold(
              body: Center(child: Text('Livre introuvable.')),
            );
          }
          return ProductDetailsPage(book: book);
        },
      ),

      GoRoute(path: '/cart', builder: (context, state) => const CartPage()),

      GoRoute(path: '/orders', builder: (context, state) => const OrdersPage()),
    ],

    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';
      final isLoginCallback = state.matchedLocation == '/login-callback';
      final isUpdatingPassword = state.matchedLocation == '/update-password';
      final isPublicLocation = {
        '/',
        '/home',
        '/details',
        '/cart',
        '/login',
        '/register',
        '/login-callback',
      }.contains(state.matchedLocation);
      final isPasswordRecovery =
          authState.valueOrNull?.event == AuthChangeEvent.passwordRecovery;

      if (isPasswordRecovery && !isUpdatingPassword) {
        return '/update-password';
      }

      if (isLoginCallback) {
        final errorCode =
            state.uri.queryParameters['error_code'] ??
            state.uri.queryParameters['error'];
        if (errorCode != null) {
          return Uri(
            path: '/login',
            queryParameters: {'authError': errorCode},
          ).toString();
        }
        return isLoggedIn ? '/home' : '/login';
      }

      if (isUpdatingPassword && !isLoggedIn) return '/login';

      if (!isLoggedIn && !isPublicLocation) {
        return Uri(
          path: '/login',
          queryParameters: {'returnTo': state.uri.toString()},
        ).toString();
      }

      if (isLoggedIn && (isGoingToLogin || isGoingToRegister)) {
        final returnTo = state.uri.queryParameters['returnTo'];
        if (returnTo != null &&
            returnTo.startsWith('/') &&
            !returnTo.startsWith('//') &&
            !returnTo.startsWith('/login')) {
          return returnTo;
        }
        return '/home';
      }

      return null;
    },
  );
});
