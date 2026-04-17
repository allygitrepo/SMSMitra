import 'package:hive_flutter/hive_flutter.dart';

part 'user_model.g.dart';

/// Represents a user in the system.
/// This model is stored locally using Hive.
@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String fullName;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final String password;

  UserModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  /// Creates a copy of the user with modified fields.
  UserModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? password,
  }) {
    return UserModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
    );
  }
}
