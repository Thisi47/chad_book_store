import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chad_book_store/app.dart';
import 'package:chad_book_store/core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase

  await Supabase.initialize(
    url: AppConstants.supabaseUrl, 
    anonKey: AppConstants.supabaseAnonKey
  );

  // Lancement de l'application avec Riverpod (ProviderScope)
  runApp(
    const ProviderScope(
      child: ChadBookStore()
    )
  );
}