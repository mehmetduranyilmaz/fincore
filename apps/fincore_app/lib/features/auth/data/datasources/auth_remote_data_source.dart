import 'package:fincore_app/features/auth/data/models/login_response_dto.dart';

abstract interface class AuthRemoteDataSource {
  Future<LoginResponseDto> login({
    required String email,
    required String password,
  });

  Future<LoginResponseDto> refresh({required String refreshToken});

  Future<void> logout();
}
