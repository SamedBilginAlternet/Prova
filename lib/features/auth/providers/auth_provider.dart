import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

part 'auth_provider.g.dart';

/// Streams Supabase auth state changes.
/// Used by the router to decide which screens to show.
@riverpod
Stream<AuthState> authState(Ref ref) {
  return supabase.auth.onAuthStateChange;
}

/// Current session — null if not logged in.
@riverpod
Session? currentSession(Ref ref) {
  return supabase.auth.currentSession;
}

/// Current user — null if not logged in.
@riverpod
User? currentUser(Ref ref) {
  return supabase.auth.currentUser;
}

/// Auth operations (sign in, sign up, sign out).
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

class AuthRepository {
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<void> signInWithGoogle() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.prova.app://login-callback',
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }
}
