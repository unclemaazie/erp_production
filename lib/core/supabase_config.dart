import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static late SupabaseClient client;

  static const String _url = String.fromEnvironment('SUPABASE_URL', defaultValue: 'YOUR_SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'YOUR_SUPABASE_ANON_KEY');

  static Future<void> init() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
      debug: kDebugMode,
    );
    client = Supabase.instance.client;
  }

  static bool get isConfigured =>
      !_url.contains('YOUR_SUPABASE_URL') && !_anonKey.contains('YOUR_SUPABASE_ANON_KEY');
}
