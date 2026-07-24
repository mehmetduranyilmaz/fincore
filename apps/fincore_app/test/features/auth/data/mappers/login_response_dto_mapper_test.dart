import 'package:fincore_app/features/auth/data/mappers/login_response_dto_mapper.dart';
import 'package:fincore_app/features/auth/data/models/login_response_dto.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps LoginResponseDto to AuthSession', () {
    const response = LoginResponseDto(
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
      expiresIn: 3600,
      tokenType: 'Bearer',
      userId: 'user-1',
      email: 'demo@fincore.app',
      fullName: 'Demo User',
    );

    expect(
      response.toEntity(),
      const AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresIn: 3600,
        tokenType: 'Bearer',
        userId: 'user-1',
        email: 'demo@fincore.app',
        fullName: 'Demo User',
      ),
    );
  });
}
