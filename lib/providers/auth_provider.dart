import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// AuthService provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

// User profile provider
final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserProfile(uid);
});

// Auth state notifier for managing auth operations
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      state = AsyncValue.data(user);
    });
  }

  // Sign up
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AsyncValue.data(_authService.currentUser);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Sign in
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(_authService.currentUser);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Resend email verification
  Future<void> resendEmailVerification() async {
    try {
      await _authService.resendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // Reload user
  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
    } catch (e) {
      rethrow;
    }
  }
}

// Auth notifier provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
