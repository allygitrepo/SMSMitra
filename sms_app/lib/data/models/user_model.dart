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

  @HiveField(4)
  final String? deviceCode;

  @HiveField(5)
  final String? createdAt;

  @HiveField(6)
  final String? profilePath;

  @HiveField(7)
  final int? id;

  @HiveField(8)
  final String? whatsappInstanceKey;

  @HiveField(9)
  final String? whatsappProfileImage;

  @HiveField(10)
  final String? whatsappPhone;

  @HiveField(11)
  final String? whatsappName;

  UserModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    this.deviceCode,
    this.createdAt,
    this.profilePath,
    this.id,
    this.whatsappInstanceKey,
    this.whatsappProfileImage,
    this.whatsappPhone,
    this.whatsappName,
  });

  /// Creates a copy of the user with modified fields.
  UserModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? password,
    String? deviceCode,
    String? createdAt,
    String? profilePath,
    int? id,
    String? whatsappInstanceKey,
    String? whatsappProfileImage,
    String? whatsappPhone,
    String? whatsappName,
  }) {
    return UserModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      deviceCode: deviceCode ?? this.deviceCode,
      createdAt: createdAt ?? this.createdAt,
      profilePath: profilePath ?? this.profilePath,
      id: id ?? this.id,
      whatsappInstanceKey: whatsappInstanceKey ?? this.whatsappInstanceKey,
      whatsappProfileImage: whatsappProfileImage ?? this.whatsappProfileImage,
      whatsappPhone: whatsappPhone ?? this.whatsappPhone,
      whatsappName: whatsappName ?? this.whatsappName,
    );
  }
}
