import 'package:chad_book_store/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:chad_book_store/core/constants/app_constants.dart';
import 'package:chad_book_store/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chad_book_store/core/theme/theme_controller.dart';

class ChadBookStore extends ConsumerWidget {
  const ChadBookStore({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
