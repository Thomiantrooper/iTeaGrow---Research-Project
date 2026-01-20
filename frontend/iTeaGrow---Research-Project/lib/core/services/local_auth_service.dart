import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}

/// Service for managing local authentication persistence
/// Stores session data in SharedPreferences for auto-login functionality
class LocalAuthService {
  final SharedPreferences _prefs;
  final DatabaseHelper _db = DatabaseHelper.instance;

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
  Future<void> saveSession(User user, {String? accessToken}) async {
    await _prefs.setString(AuthKeys.userId, user.id);
    await _prefs.setBool(AuthKeys.isLoggedIn, true);
    await _prefs.setString(AuthKeys.lastLoginTime, DateTime.now().toIso8601String());

    // Store API token if provided
    if (accessToken != null && accessToken.isNotEmpty) {
      await _prefs.setString(AuthKeys.apiToken, accessToken);
    }

    // Always store full user data for web and as backup
    final userData = jsonEncode(user.toMap());
    await _prefs.setString(AuthKeys.userData, userData);

    debugPrint('Session saved for user: ${user.username}');
  }

  /// Clear user session on logout
  Future<void> clearSession() async {
    await _prefs.remove(AuthKeys.userId);
    await _prefs.setBool(AuthKeys.isLoggedIn, false);
    await _prefs.remove(AuthKeys.lastLoginTime);
    await _prefs.remove(AuthKeys.sessionToken);
    await _prefs.remove(AuthKeys.userData);
    await _prefs.remove(AuthKeys.apiToken);

    debugPrint('Session cleared');
  }

  /// Restore user from saved session
  /// Returns null if no valid session exists
  Future<User?> restoreSession() async {
    debugPrint('Attempting to restore session...');
    debugPrint('isLoggedIn: $isLoggedIn');

    if (!isLoggedIn) {
      debugPrint('Not logged in, returning null');
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
        debugPrint('Session restored from stored data for user: ${user.username}');
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
            debugPrint('Session restored from database for user: ${user.username}');
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
