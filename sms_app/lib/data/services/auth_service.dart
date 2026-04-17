import 'storage_service.dart';
import '../models/user_model.dart';

/// A service to handle authentication logic like login and registration.
class AuthService {
  /// Registers a new user and saves them locally.
  Future<bool> register(UserModel user) async {
    try {
      await StorageService.saveUser(user);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logs in a user by validating credentials against local storage.
  Future<Map<String, dynamic>> login(String identity, String password) async {
    final user = StorageService.getUser();
    
    if (user == null) {
      return {'success': false, 'message': 'No user registered on this device'};
    }

    // Check if identity (email or phone) and password match
    bool identityMatch = (user.email == identity || user.phoneNumber == identity);
    bool passwordMatch = (user.password == password);

    if (identityMatch && passwordMatch) {
      await StorageService.setLoggedIn(true);
      return {'success': true, 'message': 'Login successful'};
    } else if (!identityMatch) {
      return {'success': false, 'message': 'Credentials do not match the registered user'};
    } else {
      return {'success': false, 'message': 'Incorrect password'};
    }
  }

  /// Logout (clears user from storage if needed, but per requirements we just check registration)
  Future<void> logout() async {
    await StorageService.setLoggedIn(false);
  }
}
