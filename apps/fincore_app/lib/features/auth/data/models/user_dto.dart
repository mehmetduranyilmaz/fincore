import 'package:fincore_app/features/auth/domain/entities/user.dart';

final class UserDto {
  const UserDto({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isActive,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  final String id;
  final String fullName;
  final String email;
  final bool isActive;

  User toEntity() {
    return User(id: id, fullName: fullName, email: email, isActive: isActive);
  }
}
