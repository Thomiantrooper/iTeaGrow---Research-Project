import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_simple.dart';
import '../../../../core/enums/app_enums.dart';

// Simple auth state provider
final authStateSimpleProvider =
    StateNotifierProvider<AuthNotifierSimple, UserSimple?>((ref) {
  return AuthNotifierSimple();
});

class AuthNotifierSimple extends StateNotifier<UserSimple?> {
  AuthNotifierSimple() : super(null);

  bool login(String username, String password) {
    debugPrint('AuthNotifier.login called: username="$username"');

    // Simple hardcoded authentication for demo
    if (username == 'manager' && password == 'manager123') {
      debugPrint('AuthNotifier: Manager credentials matched!');
      state = UserSimple(
        id: 2,
        username: 'manager',
        fullName: 'Tea Manager',
        role: UserRole.manager,
      );
      return true;
    } else if (username == 'farmer' && password == 'farmer123') {
      debugPrint('AuthNotifier: Farmer credentials matched!');
      state = UserSimple(
        id: 3,
        username: 'farmer',
        fullName: 'Tea Farmer',
        role: UserRole.farmer,
      );
      return true;
    }

    debugPrint('AuthNotifier: No credentials matched');
    return false;
  }

  void logout() {
    debugPrint('AuthNotifier: Logging out');
    state = null;
  }
}
