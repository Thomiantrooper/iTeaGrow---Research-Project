import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/local_auth_service.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/services/api_service.dart';
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

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
}

/// Auth state provider with session persistence
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(localAuthServiceProvider),
    ref.read(googleAuthServiceProvider),
  ),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final LocalAuthService _localAuthService;
  final GoogleAuthService _googleAuthService;

  AuthNotifier(
    this._authRepository,
    this._localAuthService,
    this._googleAuthService,
  ) : super(const AuthState()) {
    _initializeAuth();
  }

  /// Initialize authentication state from stored session
  Future<void> _initializeAuth() async {
    state = state.copyWith(status: AuthStatus.loading);

    // Pre-warm the Railway API server immediately so it's awake
    // by the time the user taps Login (fire-and-forget).
    ApiService.warmUp();

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
  Future<bool> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await _authRepository.loginWithToken(username, password);

      if (response != null) {
        // Save session with access token for auto-login
        await _localAuthService.saveSession(
          response.user,
          accessToken: response.accessToken,
          rememberMe: rememberMe,
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
    await _googleAuthService.signOut(); // Sign out from Google if signed in
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

      final updatedUser =
          currentUser.copyWith(languagePreference: languageCode);
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
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
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

  // ========== PIN Authentication ==========

  bool get isPinEnabled => _localAuthService.isPinEnabled;

  /// Login with PIN authentication
  Future<bool> loginWithPin(String pin) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      if (!_localAuthService.isPinEnabled) {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'PIN login is not enabled',
        );
        return false;
      }

      final isValid = await _localAuthService.verifyPin(pin);
      if (!isValid) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Invalid PIN code',
        );
        return false;
      }

      final credentials = await _localAuthService.getPinCredentials();
      if (credentials == null) {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'PIN credentials not found',
        );
        return false;
      }

      return await login(
        credentials['username']!,
        credentials['password']!,
        rememberMe: true,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'PIN login failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Enable PIN login for current user
  Future<bool> enablePinLogin(String password, String pin) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      // Verify password first
      final verified = await _authRepository.login(user.username, password);
      if (verified == null) {
        state = state.copyWith(errorMessage: 'Password wrong');
        return false;
      }

      // Enable PIN login
      await _localAuthService.enablePinLogin(user.username, password, pin);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to enable PIN login: ${e.toString()}',
      );
      return false;
    }
  }

  /// Disable PIN login
  Future<void> disablePinLogin() async {
    await _localAuthService.disablePinLogin();
  }

  /// Check if PIN login is enabled
  Future<bool> isPinLoginEnabled() async {
    return _localAuthService.isPinEnabled;
  }

  // ========== Biometric Authentication ==========

  Future<bool> loginWithBiometrics() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      // Check if biometric is enabled
      if (!_localAuthService.isBiometricEnabled) {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Biometric login is not enabled',
        );
        return false;
      }

      // Authenticate with biometrics
      final authenticated = await _localAuthService.authenticateWithBiometrics(
        reason: 'Authenticate to access your iTeaGrow account',
      );

      if (!authenticated) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Biometric authentication failed',
        );
        return false;
      }

      // Get stored credentials
      final credentials = await _localAuthService.getBiometricCredentials();
      if (credentials == null) {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Biometric credentials not found',
        );
        return false;
      }

      // Login with stored credentials
      return await login(
        credentials['username']!,
        credentials['password']!,
        rememberMe: true,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Biometric login failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Enable biometric login for current user
  Future<bool> enableBiometricLogin(String password) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      // Verify password first
      final verified = await _authRepository.login(user.username, password);
      if (verified == null) {
        state = state.copyWith(errorMessage: 'Password wrong');
        return false;
      }

      // Check if biometric is available
      final isAvailable = await _localAuthService.isBiometricAvailable();
      if (!isAvailable) {
        state = state.copyWith(
          errorMessage:
              'Biometric authentication is not available on this device',
        );
        return false;
      }

      // Authenticate with biometrics to confirm
      final authenticated = await _localAuthService.authenticateWithBiometrics(
        reason: 'Authenticate to enable biometric login',
      );

      if (!authenticated) {
        state = state.copyWith(errorMessage: 'Biometric authentication failed');
        return false;
      }

      // Enable biometric login
      await _localAuthService.enableBiometricLogin(user.username, password);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to enable biometric login: ${e.toString()}',
      );
      return false;
    }
  }

  /// Disable biometric login
  Future<void> disableBiometricLogin() async {
    await _localAuthService.disableBiometricLogin();
  }

  /// Check if biometric is available
  Future<bool> isBiometricAvailable() async {
    return await _localAuthService.isBiometricAvailable();
  }

  /// Check if biometric is enabled
  bool get isBiometricEnabled => _localAuthService.isBiometricEnabled;

  // ========== Google Sign-In ==========

  /// Login with Google Sign-In
  Future<bool> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      // Sign in with Google
      final googleAccount = await _googleAuthService.signIn();

      if (googleAccount == null) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Google Sign-In cancelled',
        );
        return false;
      }

      // Get Google ID token for backend verification
      final idToken = await _googleAuthService.getIdToken();

      if (idToken == null) {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Failed to get Google authentication token',
        );
        return false;
      }

      debugPrint('Google Sign-In successful: ${googleAccount.email}');

      // Send Google ID token to our backend for verification and role check
      final authResponse = await _authRepository.loginWithGoogleToken(idToken);

      if (authResponse != null) {
        // Save session locally with our backend's API token
        await _localAuthService.saveSession(
          authResponse.user,
          accessToken: authResponse.accessToken,
          rememberMe: true,
        );

        state = AuthState(
          status: AuthStatus.authenticated,
          user: authResponse.user,
          accessToken: authResponse.accessToken,
        );

        debugPrint(
            'Google user session saved from backend: ${authResponse.user.username}');
        return true;
      } else {
        // Backend rejected (e.g., admin account or deactivated)
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Google Sign-In failed. Account not registered or deactivated.',
        );
        // Sign out of Google so they can try another account next time
        await _googleAuthService.signOut();
        return false;
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Google Sign-In failed: ${e.toString()}',
      );
      return false;
    }
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
