import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseConfig.client;

  static Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  static Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;
  static bool get isAuthenticated => currentUser != null;
}
