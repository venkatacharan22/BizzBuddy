import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<ApiUser?>>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<ApiUser?>> {
  final ApiService _apiService;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiService) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Try to get stored token
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        // Validate token
        final isValid = await _apiService.validateToken(token);
        if (isValid) {
          // Get user data
          final user = await _apiService.getCurrentUser();
          state = AsyncValue.data(user);
        } else {
          await _storage.delete(key: 'auth_token');
          state = const AsyncValue.data(null);
        }
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final user = await _apiService.login(
        email: email,
        password: password,
      );

      // Store token
      await _storage.write(key: 'auth_token', value: user.token);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final user = await _apiService.register(
        name: name,
        email: email,
        password: password,
      );

      // Store token
      await _storage.write(key: 'auth_token', value: user.token);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: 'auth_token');
      _apiService.clearAuth();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    try {
      state = const AsyncValue.loading();
      final user = await _apiService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
