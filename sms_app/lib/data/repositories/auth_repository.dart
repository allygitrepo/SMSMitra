import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exceptions.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../providers/user_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref);
});

/// Central Authentication Repository managing login, registration, token persistence, and profile lifecycle.
class AuthRepository {
  final Ref _ref;
  final AuthService _authService = AuthService();

  AuthRepository(this._ref);

  /// Authenticates user and securely stores JWT token.
  Future<Map<String, dynamic>> login(String emailOrPhone, String password) async {
    if (emailOrPhone.isEmpty || password.isEmpty) {
      throw const ValidationException('Email/Phone and password are required.');
    }

    final result = await _authService.login(emailOrPhone, password);
    if (result['success'] == true) {
      _ref.read(userProvider.notifier).refresh();
      return result;
    } else {
      throw AuthException(result['message'] ?? 'Login failed. Please check your credentials.');
    }
  }

  /// Registers a new user account.
  Future<Map<String, dynamic>> register(UserModel user) async {
    final result = await _authService.register(user);
    if (result['success'] == true) {
      _ref.read(userProvider.notifier).refresh();
      return result;
    } else {
      throw AuthException(result['message'] ?? 'Registration failed.');
    }
  }

  /// Updates profile information.
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    final user = StorageService.getUser();
    if (user == null) throw const AuthException('No active user session.');

    final result = await _authService.updateProfile(
      userId: user.id.toString(),
      fullName: fullName,
      phoneNumber: phoneNumber,
    );

    if (result['success'] == true) {
      _ref.read(userProvider.notifier).refresh();
      return result;
    } else {
      throw NetworkException(result['message'] ?? 'Profile update failed.');
    }
  }

  /// Logs out user and purges sensitive tokens.
  Future<void> logout() async {
    await _authService.logout();
    _ref.read(userProvider.notifier).clear();
  }

  /// Checks if user is authenticated.
  bool isAuthenticated() {
    return StorageService.isLoggedIn() && StorageService.getUser() != null;
  }
}
