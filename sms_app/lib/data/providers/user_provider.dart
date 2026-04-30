import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

/// Provider that manages the current user state reactively.
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(StorageService.getUser());

  void refresh() {
    state = StorageService.getUser();
  }

  void setUser(UserModel user) {
    state = user;
    StorageService.saveUser(user);
  }

  void clear() {
    state = null;
  }
}
