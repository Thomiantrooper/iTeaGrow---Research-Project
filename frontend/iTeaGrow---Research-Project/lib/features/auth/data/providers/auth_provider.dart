import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../../domain/models/user.dart';

// Auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AsyncValue.data(null));

  Future<bool> login(String username, String password) async {
    state = const AsyncValue.loading();

    try {
      final user = await _authRepository.login(username, password);

      if (user != null) {
        state = AsyncValue.data(user);
        return true;
      } else {
        state = const AsyncValue.data(null);
        return false;
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  void logout() {
    state = const AsyncValue.data(null);
  }

  Future<void> updateLanguage(String languageCode) async {
    final currentUser = state.value;
    if (currentUser != null) {
      await _authRepository.updateUser(
        currentUser.id,
        {'language_preference': languageCode},
      );

      state = AsyncValue.data(
        currentUser.copyWith(languagePreference: languageCode),
      );
    }
  }

  User? get currentUser => state.value;
}
