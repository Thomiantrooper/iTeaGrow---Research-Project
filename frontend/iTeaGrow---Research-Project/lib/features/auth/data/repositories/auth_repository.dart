import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/user.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<User?> login(String username, String password) async {
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

      // Simple hash comparison (in production, use bcrypt or similar)
      final inputHash = _hashPassword(password);

      if (storedHash == inputHash) {
        return User.fromMap(user);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createUser({
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
      return false;
    }
  }

  Future<bool> updateUser(int userId, Map<String, dynamic> updates) async {
    try {
      await _db.update(
        'users',
        updates,
        'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(int userId, String newPassword) async {
    try {
      final passwordHash = _hashPassword(newPassword);
      await _db.update(
        'users',
        {'password_hash': passwordHash},
        'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final users = await _db.query('users');
      return users.map((u) => User.fromMap(u)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      await _db.delete('users', 'id = ?', whereArgs: [userId]);
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
  return AuthRepository();
});
