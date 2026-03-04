import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/domain/models/user.dart';
import '../database/database_helper.dart';

/// Keys for SharedPreferences storage
class AuthKeys {
  static const String userId = 'auth_user_id';
  static const String isLoggedIn = 'auth_is_logged_in';
  static const String lastLoginTime = 'auth_last_login';
  static const String sessionToken = 'auth_session_token';
  static const String userData = 'auth_user_data';
  static const String apiToken = 'api_access_token';
  static const String rememberMe = 'auth_remember_me';
  static const String biometricEnabled = 'auth_biometric_enabled';
  static const String biometricUsername = 'auth_biometric_username';
  static const String pinEnabled = 'auth_pin_enabled';
  static const String pinUsername = 'auth_pin_username';
}

/// Service for managing local authentication persistence
/// Stores session data in SharedPreferences for auto-login functionality
class LocalAuthService {
  final SharedPreferences _prefs;
  final DatabaseHelper _db = DatabaseHelper.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  LocalAuthService(this._prefs);

  /// Check if user is currently logged in
  bool get isLoggedIn => _prefs.getBool(AuthKeys.isLoggedIn) ?? false;

  /// Get the stored user ID (as string to support MongoDB ObjectId)
  String? get storedUserId => _prefs.getString(AuthKeys.userId);

  /// Get API token
  String? get apiToken => _prefs.getString(AuthKeys.apiToken);

  /// Check if API token exists
  bool get hasApiToken => apiToken != null && apiToken!.isNotEmpty;

  /// Get last login timestamp
  DateTime? get lastLoginTime {
    final timestamp = _prefs.getString(AuthKeys.lastLoginTime);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  /// Save user session after successful login
  Future<void> saveSession(
    User user, {
    String? accessToken,
    bool rememberMe = false,
  }) async {
    // Write all prefs in parallel — avoids 5 sequential disk flushes.
    final writes = <Future>[
      _prefs.setString(AuthKeys.userId, user.id),
      _prefs.setBool(AuthKeys.isLoggedIn, true),
      _prefs.setBool(AuthKeys.rememberMe, rememberMe),
      _prefs.setString(AuthKeys.lastLoginTime, DateTime.now().toIso8601String()),
    ];
    if (accessToken != null && accessToken.isNotEmpty) {
      writes.add(_prefs.setString(AuthKeys.apiToken, accessToken));
    }
    if (rememberMe) {
      writes.add(_prefs.setString(AuthKeys.userData, jsonEncode(user.toMap())));
    }
    await Future.wait(writes);

    debugPrint(
        'Session saved for user: ${user.username} (Remember: $rememberMe)');
  }

  /// Clear user session on logout
  Future<void> clearSession() async {
    await _prefs.remove(AuthKeys.userId);
    await _prefs.setBool(AuthKeys.isLoggedIn, false);
    await _prefs.remove(AuthKeys.lastLoginTime);
    await _prefs.remove(AuthKeys.sessionToken);
    await _prefs.remove(AuthKeys.userData);
    await _prefs.remove(AuthKeys.apiToken);
    await _prefs.remove(AuthKeys.rememberMe);
    // Note: We keep biometric preferences even after logout
    // so user doesn't have to re-enable on next login

    debugPrint('Session cleared');
  }

  /// Restore user from saved session
  /// Returns null if no valid session exists or rememberMe is false
  Future<User?> restoreSession() async {
    debugPrint('Attempting to restore session...');
    debugPrint('isLoggedIn: $isLoggedIn');

    if (!isLoggedIn) {
      debugPrint('Not logged in, returning null');
      return null;
    }

    // Check if user opted for "Remember Me"
    final shouldRemember = _prefs.getBool(AuthKeys.rememberMe) ?? false;
    if (!shouldRemember) {
      debugPrint('Remember Me not enabled, clearing session');
      await clearSession();
      return null;
    }

    // Check if session is still valid (30 days expiry)
    final lastLogin = lastLoginTime;
    if (lastLogin != null) {
      final sessionAge = DateTime.now().difference(lastLogin);
      if (sessionAge.inDays > 30) {
        debugPrint('Session expired, clearing');
        await clearSession();
        return null;
      }
    }

    // Try to restore from stored user data first (works on all platforms)
    final userData = _prefs.getString(AuthKeys.userData);
    if (userData != null) {
      try {
        final userMap = jsonDecode(userData) as Map<String, dynamic>;
        final user = User.fromMap(userMap);
        debugPrint(
            'Session restored from stored data for user: ${user.username}');
        return user;
      } catch (e) {
        debugPrint('Failed to parse stored user data: $e');
      }
    }

    // On mobile, try to fetch from database
    if (!kIsWeb) {
      final userId = storedUserId;
      if (userId != null) {
        try {
          final users = await _db.queryWhere(
            'users',
            'id = ?',
            whereArgs: [int.tryParse(userId) ?? 0],
          );

          if (users.isNotEmpty) {
            final user = User.fromMap(users.first);
            debugPrint(
                'Session restored from database for user: ${user.username}');
            return user;
          }
        } catch (e) {
          debugPrint('Database error during session restore: $e');
        }
      }
    }

    debugPrint('Failed to restore session');
    await clearSession();
    return null;
  }

  /// Update stored user data (for profile updates)
  Future<void> updateStoredUser(User user) async {
    final userData = jsonEncode(user.toMap());
    await _prefs.setString(AuthKeys.userData, userData);
  }

  // ========== Biometric Authentication Methods ==========

  /// Check if biometric authentication is available on this device
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) {
      debugPrint('Biometric auth not supported on web');
      return false;
    }

    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      debugPrint('Can check biometrics: $canCheckBiometrics');
      debugPrint('Device supported: $isDeviceSupported');

      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];

    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate user with biometrics
  Future<bool> authenticateWithBiometrics({
    String reason = 'Please authenticate to access your account',
  }) async {
    if (kIsWeb) {
      debugPrint('Biometric auth not supported on web');
      return false;
    }

    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        debugPrint('Biometric authentication not available');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      debugPrint('Biometric authentication result: $authenticated');
      return authenticated;
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return false;
    }
  }

  /// Check if biometric login is enabled for current user
  bool get isBiometricEnabled {
    return _prefs.getBool(AuthKeys.biometricEnabled) ?? false;
  }

  /// Get username associated with biometric login
  String? get biometricUsername {
    return _prefs.getString(AuthKeys.biometricUsername);
  }

  /// Enable biometric login for a user
  Future<void> enableBiometricLogin(String username, String password) async {
    if (kIsWeb) {
      debugPrint('Biometric auth not supported on web');
      return;
    }

    try {
      // Store credentials securely
      await _secureStorage.write(key: 'biometric_username', value: username);
      await _secureStorage.write(key: 'biometric_password', value: password);

      // Save preferences
      await _prefs.setBool(AuthKeys.biometricEnabled, true);
      await _prefs.setString(AuthKeys.biometricUsername, username);

      debugPrint('Biometric login enabled for user: $username');
    } catch (e) {
      debugPrint('Error enabling biometric login: $e');
    }
  }

  /// Disable biometric login
  Future<void> disableBiometricLogin() async {
    try {
      // Clear secure storage
      await _secureStorage.delete(key: 'biometric_username');
      await _secureStorage.delete(key: 'biometric_password');

      // Clear preferences
      await _prefs.remove(AuthKeys.biometricEnabled);
      await _prefs.remove(AuthKeys.biometricUsername);

      debugPrint('Biometric login disabled');
    } catch (e) {
      debugPrint('Error disabling biometric login: $e');
    }
  }

  // ========== PIN Authentication Methods ==========

  bool get isPinEnabled {
    return _prefs.getBool(AuthKeys.pinEnabled) ?? false;
  }

  String? get pinUsername {
    return _prefs.getString(AuthKeys.pinUsername);
  }

  Future<void> enablePinLogin(
      String username, String password, String pin) async {
    if (kIsWeb) return;
    try {
      await _secureStorage.write(key: 'pin_username', value: username);
      await _secureStorage.write(key: 'pin_password', value: password);
      await _secureStorage.write(key: 'app_pin', value: pin);

      await _prefs.setBool(AuthKeys.pinEnabled, true);
      await _prefs.setString(AuthKeys.pinUsername, username);
      debugPrint('PIN login enabled for user: $username');
    } catch (e) {
      debugPrint('Error enabling PIN login: $e');
    }
  }

  Future<void> disablePinLogin() async {
    try {
      await _secureStorage.delete(key: 'pin_username');
      await _secureStorage.delete(key: 'pin_password');
      await _secureStorage.delete(key: 'app_pin');

      await _prefs.remove(AuthKeys.pinEnabled);
      await _prefs.remove(AuthKeys.pinUsername);
      debugPrint('PIN login disabled');
    } catch (e) {
      debugPrint('Error disabling PIN login: $e');
    }
  }

  Future<bool> verifyPin(String pin) async {
    if (kIsWeb) return false;
    try {
      final storedPin = await _secureStorage.read(key: 'app_pin');
      return storedPin == pin;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  Future<Map<String, String>?> getPinCredentials() async {
    if (kIsWeb) return null;
    try {
      final username = await _secureStorage.read(key: 'pin_username');
      final password = await _secureStorage.read(key: 'pin_password');

      if (username != null && password != null) {
        return {'username': username, 'password': password};
      }
      return null;
    } catch (e) {
      debugPrint('Error reading PIN credentials: $e');
      return null;
    }
  }

  /// Get stored biometric credentials
  Future<Map<String, String>?> getBiometricCredentials() async {
    if (kIsWeb) return null;

    try {
      final username = await _secureStorage.read(key: 'biometric_username');
      final password = await _secureStorage.read(key: 'biometric_password');

      if (username != null && password != null) {
        return {'username': username, 'password': password};
      }
      return null;
    } catch (e) {
      debugPrint('Error reading biometric credentials: $e');
      return null;
    }
  }

  /// Check if this is the first app launch
  bool get isFirstLaunch => !_prefs.containsKey(AuthKeys.isLoggedIn);

  /// Mark that app has been launched before
  Future<void> markLaunched() async {
    if (isFirstLaunch) {
      await _prefs.setBool(AuthKeys.isLoggedIn, false);
    }
  }
}

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Provider for LocalAuthService
final localAuthServiceProvider = Provider<LocalAuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalAuthService(prefs);
});
