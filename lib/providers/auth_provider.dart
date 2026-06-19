import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/user_profile.dart';

class AuthState {
  final User? user;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.profile, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({User? user, UserProfile? profile, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _init();
  }

  void _init() {
    final session = SupabaseConfig.client.auth.currentSession;
    if (session != null) {
      _loadProfile(session.user);
    }
  }

  Future<void> _loadProfile(User user) async {
    state = state.copyWith(user: user, isLoading: true);
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data != null) {
        state = state.copyWith(
          profile: UserProfile.fromMap(data),
          isLoading: false,
        );
      } else {
        state = state.copyWith(user: user, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(user: user, isLoading: false, error: e.toString());
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        await _loadProfile(res.user!);
      }
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut();
    state = AuthState();
  }

  Future<void> resetPassword(String email) async {
    await SupabaseConfig.client.auth.resetPasswordForEmail(email);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
