import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/local_auth_service.dart';
import '../repositories/auth_repository.dart';
import '../../domain/models/user.dart';

/// Authentication state enum for better state management
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Authentication state class
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? accessToken;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.accessToken,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? accessToken,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
}

/// Auth state provider with session persistence
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(localAuthServiceProvider),
  ),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final LocalAuthService _localAuthService;

  AuthNotifier(this._authRepository, this._localAuthService)
      : super(const AuthState()) {
    _initializeAuth();
  }

  /// Initialize authentication state from stored session
  Future<void> _initializeAuth() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      debugPrint('Initializing auth state...');

      // First try to restore from local storage
      final user = await _localAuthService.restoreSession();

      if (user != null) {
        debugPrint('User restored from session: ${user.username}');

        // Get stored API token if available
        final apiToken = _localAuthService.apiToken;

        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          accessToken: apiToken,
        );

        // Optionally verify token with API in background
        if (apiToken != null && apiToken.isNotEmpty) {
          _verifyTokenInBackground();
        }
      } else {
        debugPrint('No stored session found');
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Verify token with API in background
  Future<void> _verifyTokenInBackground() async {
    try {
      final verifiedUser = await _authRepository.verifyToken();
      if (verifiedUser != null) {
        // Update stored user data with latest from API
        await _localAuthService.updateStoredUser(verifiedUser);
        state = state.copyWith(user: verifiedUser);
      }
    } catch (e) {
      debugPrint('Background token verification failed: $e');
      // Don't logout on verification failure - local session is still valid
    }
  }

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await _authRepository.loginWithToken(username, password);

      if (response != null) {
        // Save session with access token for auto-login
        await _localAuthService.saveSession(
          response.user,
          accessToken: response.accessToken,
        );

        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
          accessToken: response.accessToken,
        );
        return true;
      } else {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Invalid username or password',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Logout and clear session
  Future<void> logout() async {
    await _localAuthService.clearSession();
    await _authRepository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Register a new user
  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    String role = 'farmer',
    String? email,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await _authRepository.register(
        username: username,
        password: password,
        role: role,
        fullName: fullName,
        email: email,
        phone: phone,
      );

      if (response != null) {
        // Save session with access token
        await _localAuthService.saveSession(
          response.user,
          accessToken: response.accessToken,
        );

        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
          accessToken: response.accessToken,
        );
        return true;
      } else {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Registration failed. Username may already exist.',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update user language preference
  Future<void> updateLanguage(String languageCode) async {
    final currentUser = state.user;
    if (currentUser != null) {
      await _authRepository.updateUser(
        currentUser.id,
        {'language_preference': languageCode},
      );

      final updatedUser = currentUser.copyWith(languagePreference: languageCode);
      await _localAuthService.updateStoredUser(updatedUser);

      state = state.copyWith(user: updatedUser);
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? phone,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) return false;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (email != null) updates['email'] = email;
    if (phone != null) updates['phone'] = phone;

    if (updates.isEmpty) return true;

    final success = await _authRepository.updateUser(currentUser.id, updates);

    if (success) {
      final updatedUser = currentUser.copyWith(
        fullName: fullName ?? currentUser.fullName,
        email: email ?? currentUser.email,
        phone: phone ?? currentUser.phone,
      );
      await _localAuthService.updateStoredUser(updatedUser);
      state = state.copyWith(user: updatedUser);
    }

    return success;
  }

  /// Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final currentUser = state.user;
    if (currentUser == null) return false;

    // Verify current password by attempting login
    final verified = await _authRepository.login(
      currentUser.username,
      currentPassword,
    );

    if (verified == null) {
      state = state.copyWith(errorMessage: 'Current password is incorrect');
      return false;
    }

    return await _authRepository.changePassword(currentUser.id, newPassword);
  }

  /// Get current user
  User? get currentUser => state.user;

  /// Clear any error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Convenience providers for easy access
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authStateProvider).status;
});
