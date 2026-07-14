import 'package:sms_app/data/services/storage_service.dart';
import 'package:sms_app/shared/widgets/error_handler.dart';
import 'api_service.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  /// Registers a new user on the server.
  Future<Map<String, dynamic>> register(UserModel user) async {
    try {
      final response = await _apiService.post(
        ApiConstants.register,
        data: {
          'fullName': user.fullName,
          'email': user.email,
          'phoneNumber': user.phoneNumber,
          'password': user.password,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;
        final newUser = user.copyWith(
          id: data['user']['_id'] ?? data['user']['id'],
          deviceCode: data['user']['deviceCode'],
        );
        await StorageService.saveUser(newUser);

        // Sync FCM Token for the newly registered device
        await _updateFcmToken(data['user']['deviceCode']);

        return {
          'success': true,
          'message': 'Registration successful',
          'deviceCode': data['user']['deviceCode'],
          'hasSimDetails': data['hasSimDetails'] ?? false,
        };
      }
      return {'success': false, 'message': 'Registration failed'};
    } catch (e) {
      return {
        'success': false,
        'message': ErrorHandler.getUserFriendlyMessage(e),
      };
    }
  }

  /// Logs in a user via the server.
  Future<Map<String, dynamic>> login(String identity, String password) async {
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        data: {'email': identity, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final userData = data['user'];

        // Create or update local user model with server data
        final newUser = UserModel(
          id: userData['_id'] ?? userData['id'],
          fullName: userData['fullName'] ?? 'User',
          email: userData['email'] ?? identity,
          phoneNumber: userData['phoneNumber'] ?? '',
          password: password, // Keep password for re-auth if needed
          deviceCode: userData['deviceCode'],
          whatsappInstanceKey: userData['whatsappInstanceKey'],
          whatsappProfileImage: userData['whatsappProfileImage'],
          whatsappPhone: userData['whatsappPhone'],
          whatsappName: userData['whatsappName'],
        );

        await StorageService.saveUser(newUser);

        // Save the logged-in state
        await StorageService.setLoggedIn(true);
        
        // Sync FCM Token
        await _updateFcmToken(data['user']['deviceCode']);

        return {
          'success': true, 
          'message': 'Login successful',
          'user': data['user'],
          'hasSimDetails': data['hasSimDetails'] ?? false,
        };
      }
      return {'success': false, 'message': 'Invalid credentials'};
    } catch (e) {
      return {'success': false, 'message': ErrorHandler.getUserFriendlyMessage(e)};
    }
  }

  /// Private helper to sync FCM token with the server
  Future<void> _updateFcmToken(String deviceCode) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _apiService.post(
          ApiConstants.updateToken,
          data: {
            'deviceCode': deviceCode,
            'fcmToken': fcmToken,
          },
        );
      }
    } catch (e) {
      print('FCM Token Sync Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.updateProfile,
        data: {
          'userId': userId,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        },
      );

      if (response.statusCode == 200) {
        final userData = response.data['user'];
        final currentUser = StorageService.getUser();
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(
            fullName: userData['fullName'],
            phoneNumber: userData['phoneNumber'],
          );
          await StorageService.saveUser(updatedUser);
          return {'success': true, 'message': 'Profile updated successfully', 'user': updatedUser};
        }
      }
      return {'success': false, 'message': 'Update failed'};
    } catch (e) {
      return {'success': false, 'message': ErrorHandler.getUserFriendlyMessage(e)};
    }
  }

  Future<void> logout() async {
    await StorageService.setLoggedIn(false);
  }
}
