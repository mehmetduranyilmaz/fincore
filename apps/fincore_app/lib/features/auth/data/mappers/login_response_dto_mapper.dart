import 'package:fincore_app/features/auth/data/models/login_response_dto.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';

extension LoginResponseDtoMapper on LoginResponseDto {
  AuthSession toEntity() {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      tokenType: tokenType,
      userId: userId,
      email: email,
      fullName: fullName,
    );
  }
}
