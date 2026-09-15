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
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.register,
        data: {
          'fullName': user.fullName,
          'email': user.email,
          'phoneNumber': user.phoneNumber,
          'password': user.password,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data!;
        final token = data['token'];
        if (token != null) {
          await StorageService.saveToken(token.toString());
        }

        final userData = data['user'] as Map<String, dynamic>?;
        final rawId = userData?['_id'] ?? userData?['id'];
        final deviceCode = userData?['deviceCode']?.toString();

        final newUser = user.copyWith(
          id: rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? ''),
          deviceCode: deviceCode,
        );
        await StorageService.saveUser(newUser);
        await StorageService.setLoggedIn(true);

        // Sync FCM Token for the newly registered device
        if (deviceCode != null) {
          await _updateFcmToken(deviceCode);
        }

        return {
          'success': true,
          'message': 'Registration successful',
          'deviceCode': deviceCode,
          'hasSimDetails': data['hasSimDetails'] == true,
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
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {'email': identity, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final token = data['token'];
        if (token != null) {
          await StorageService.saveToken(token.toString());
        }

        final userData = (data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final rawId = userData['_id'] ?? userData['id'];
        final deviceCode = userData['deviceCode']?.toString();

        // Create or update local user model with server data
        final newUser = UserModel(
          id: rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? ''),
          fullName: userData['fullName']?.toString() ?? 'User',
          email: userData['email']?.toString() ?? identity,
          phoneNumber: userData['phoneNumber']?.toString() ?? '',
          password: password, // Keep password for re-auth if needed
          deviceCode: deviceCode,
        );

        await StorageService.saveUser(newUser);

        // Save the logged-in state
        await StorageService.setLoggedIn(true);
        
        // Sync FCM Token
        if (deviceCode != null) {
          await _updateFcmToken(deviceCode);
        }

        return {
          'success': true, 
          'message': 'Login successful',
          'user': data['user'],
          'hasSimDetails': data['hasSimDetails'] == true,
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
        await _apiService.post<dynamic>(
          ApiConstants.updateToken,
          data: {
            'deviceCode': deviceCode,
            'fcmToken': fcmToken,
          },
        );
      }
    } catch (e) {
      // Ignore FCM background error
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.updateProfile,
        data: {
          'userId': userId,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data!['user'] as Map<String, dynamic>?;
        final currentUser = StorageService.getUser();
        if (currentUser != null && userData != null) {
          final updatedUser = currentUser.copyWith(
            fullName: userData['fullName']?.toString() ?? currentUser.fullName,
            phoneNumber: userData['phoneNumber']?.toString() ?? currentUser.phoneNumber,
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
    await StorageService.clearSession();
  }
}
