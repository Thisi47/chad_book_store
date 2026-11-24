import 'package:flutter/foundation.dart';

class AppConstants {
  static const appName = "Tchad Books";
  static const appCurrency = "F CFA";
  static const supabaseUrl = "https://snjufojacjsxoyugkmou.supabase.co";
  static const supabaseAnonKey =
      "sb_publishable_ok5zLzjFgcljU1G9NwpPww_0h8oUJdB";
  static String get authRedirectUrl => kIsWeb
      ? Uri.base.resolve('/login-callback').toString()
      : "chadbookstore://login-callback/";

  static const int connectTime = 30000; // 30 s
}
