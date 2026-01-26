import 'package:chad_book_store/routing/app_router.dart';
import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
import 'package:chad_book_store/core/constants/app_constants.dart';
import 'package:chad_book_store/core/theme/app_theme.dart';

class ChadBookStore extends StatelessWidget {
  const ChadBookStore({super.key});

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}