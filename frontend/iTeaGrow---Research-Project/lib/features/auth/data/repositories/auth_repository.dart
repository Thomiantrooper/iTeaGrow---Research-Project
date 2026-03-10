import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/api/api_config.dart';
import '../../domain/models/user.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Authentication response from API
class AuthResponse {
  final String accessToken;
  final User user;

  AuthResponse({required this.accessToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      user: User.fromApiResponse(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthRepository {
  final ApiService? _apiService;
  final DatabaseHelper _db = DatabaseHelper.instance;
  final bool _useApi;

  AuthRepository({ApiService? apiService})
      : _apiService = apiService,
        _useApi = apiService != null;

  /// Login with username and password - returns AuthResponse with token
  Future<AuthResponse?> loginWithToken(String username, String password) async {
    // Try API first if available
    if (_useApi && _apiService != null) {
      try {
        debugPrint('Attempting API login for user: $username');
        final response = await _apiService.post<Map<String, dynamic>>(
          ApiConfig.authLogin,
          body: {
            'username': username,
            'password': password,
          },
          fromJson: (data) => data as Map<String, dynamic>,
        );

        debugPrint(
            'API login response: success=${response.success}, statusCode=${response.statusCode}');

        if (response.success && response.data != null) {
          final authResponse = AuthResponse.fromJson(response.data!);
          await _apiService.saveToken(authResponse.accessToken);
          debugPrint('API login successful, token saved');
          return authResponse;
        } else {
          debugPrint('API login failed: ${response.error}');
          // On web, don't fallback to local - return null to show error
          if (kIsWeb) return null;
        }
      } catch (e) {
        debugPrint('API login exception: $e');
        // On web, don't fallback to local - return null to show error
        if (kIsWeb) return null;
      }
    }

    // Fallback to local database (only on mobile/desktop)
    if (!kIsWeb) {
      final user = await _loginLocal(username, password);
      if (user != null) {
        return AuthResponse(accessToken: '', user: user);
      }
    }
    return null;
  }

  /// Login with username and password (backward compatibility - returns just User)
  Future<User?> login(String username, String password) async {
    final response = await loginWithToken(username, password);
    return response?.user;
  }

  /// Login with Google ID Token - returns AuthResponse with token (Managers Only)
  Future<AuthResponse?> loginWithGoogleToken(String idToken) async {
    if (_useApi && _apiService != null) {
      try {
        debugPrint('Attempting API Google login');
        final response = await _apiService.post<Map<String, dynamic>>(
          ApiConfig.authGoogleLogin,
          body: {'id_token': idToken},
          fromJson: (data) => data as Map<String, dynamic>,
          timeout: const Duration(seconds: 30),
        );

        debugPrint(
            'API Google login response: success=${response.success}, statusCode=${response.statusCode}');

        if (response.success && response.data != null) {
          final authResponse = AuthResponse.fromJson(response.data!);
          await _apiService.saveToken(authResponse.accessToken);
          debugPrint('API Google login successful, token saved');
          return authResponse;
        } else {
          debugPrint('API Google login failed: ${response.error}');
          return null; // Don't fallback to local for Google Auth
        }
      } catch (e) {
        debugPrint('API Google login exception: $e');
        return null;
      }
    }
    return null;
  }

  /// Local login fallback
  Future<User?> _loginLocal(String username, String password) async {
    try {
      final users = await _db.queryWhere(
        'users',
        'username = ?',
        whereArgs: [username],
      );

      if (users.isEmpty) {
        return null;
      }

      final user = users.first;
      final storedHash = user['password_hash'] as String;
      final inputHash = _hashPassword(password);

      if (storedHash == inputHash) {
        return User.fromMap(user);
      }

      return null;
    } catch (e) {
      debugPrint('Local login error: $e');
      return null;
    }
  }

  /// Register a new user
  Future<AuthResponse?> register({
    required String username,
    required String password,
    required String role,
    required String fullName,
    String? email,
    String? phone,
  }) async {
    // Try API first if available
    if (_useApi && _apiService != null) {
      try {
        debugPrint('Attempting API registration for user: $username');
        final response = await _apiService.post<Map<String, dynamic>>(
          ApiConfig.authRegister,
          body: {
            'username': username,
            'password': password,
            'full_name': fullName,
            'role': role,
            'email': email,
            'phone': phone,
            'language_preference': 'en',
          },
          fromJson: (data) => data as Map<String, dynamic>,
        );

        debugPrint(
            'API registration response: success=${response.success}, statusCode=${response.statusCode}');

        if (response.success && response.data != null) {
          final authResponse = AuthResponse.fromJson(response.data!);
          await _apiService.saveToken(authResponse.accessToken);
          debugPrint('API registration successful');
          return authResponse;
        } else {
          debugPrint('API registration failed: ${response.error}');
          // On web, don't fallback to local - return null to show error
          if (kIsWeb) return null;
        }
      } catch (e) {
        debugPrint('API registration exception: $e');
        // On web, don't fallback to local - return null to show error
        if (kIsWeb) return null;
      }
    }

    // Fallback to local registration (only on mobile/desktop)
    if (!kIsWeb) {
      final success = await _createUserLocal(
        username: username,
        password: password,
        role: role,
        fullName: fullName,
        email: email,
        phone: phone,
      );

      if (success) {
        final user = await _loginLocal(username, password);
        if (user != null) {
          return AuthResponse(accessToken: '', user: user);
        }
      }
    }

    return null;
  }

  /// Create user (backward compatibility)
  Future<bool> createUser({
    required String username,
    required String password,
    required String role,
    required String fullName,
    String? email,
    String? phone,
  }) async {
    final response = await register(
      username: username,
      password: password,
      role: role,
      fullName: fullName,
      email: email,
      phone: phone,
    );
    return response != null;
  }

  /// Create user in local database
  Future<bool> _createUserLocal({
    required String username,
    required String password,
    required String role,
    required String fullName,
    String? email,
    String? phone,
  }) async {
    try {
      final passwordHash = _hashPassword(password);

      await _db.insert('users', {
        'username': username,
        'password_hash': passwordHash,
        'role': role,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'created_at': DateTime.now().toIso8601String(),
        'language_preference': 'en',
      });

      return true;
    } catch (e) {
      debugPrint('Local user creation error: $e');
      return false;
    }
  }

  /// Verify token and get current user
  Future<User?> verifyToken() async {
    if (!_useApi || _apiService == null || !_apiService.hasToken) {
      return null;
    }

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.authVerifyToken,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        return User.fromApiResponse(response.data!);
      }
    } catch (e) {
      debugPrint('Token verification failed: $e');
    }

    return null;
  }

  /// Update user profile
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    if (_useApi && _apiService != null) {
      try {
        final response = await _apiService.put<Map<String, dynamic>>(
          ApiConfig.authProfile,
          body: updates,
          fromJson: (data) => data as Map<String, dynamic>,
        );

        if (response.success) {
          return true;
        }
      } catch (e) {
        debugPrint('API update failed: $e');
      }
    }

    // Fallback to local update
    try {
      await _db.update(
        'users',
        updates,
        'id = ?',
        whereArgs: [int.tryParse(userId) ?? 0],
      );
      return true;
    } catch (e) {
      debugPrint('Local update error: $e');
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword(String userId, String newPassword) async {
    if (_useApi && _apiService != null) {
      // Note: API requires current password verification
      // This would need to be called differently from the UI
      try {
        final passwordHash = _hashPassword(newPassword);
        await _db.update(
          'users',
          {'password_hash': passwordHash},
          'id = ?',
          whereArgs: [int.tryParse(userId) ?? 0],
        );
        return true;
      } catch (e) {
        debugPrint('Password change error: $e');
        return false;
      }
    }

    try {
      final passwordHash = _hashPassword(newPassword);
      await _db.update(
        'users',
        {'password_hash': passwordHash},
        'id = ?',
        whereArgs: [int.tryParse(userId) ?? 0],
      );
      return true;
    } catch (e) {
      debugPrint('Local password change error: $e');
      return false;
    }
  }

  /// Logout - clear API token
  Future<void> logout() async {
    if (_apiService != null) {
      await _apiService.clearToken();
    }
  }

  /// Get all users (local only)
  Future<List<User>> getAllUsers() async {
    try {
      final users = await _db.query('users');
      return users.map((u) => User.fromMap(u)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await _db
          .delete('users', 'id = ?', whereArgs: [int.tryParse(userId) ?? 0]);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  try {
    final apiService = ref.watch(apiServiceProvider);
    return AuthRepository(apiService: apiService);
  } catch (e) {
    // API service not available, use local-only mode
    return AuthRepository();
  }
});
