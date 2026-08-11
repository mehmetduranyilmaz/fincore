import 'package:fincore_app/core/network/exceptions/api_exception.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/data/models/login_response_dto.dart';

final class DevAuthRemoteDataSource implements AuthRemoteDataSource {
  const DevAuthRemoteDataSource();

  static const String email = 'dev@fincore.app';
  static const String password = '123456';
  static const String _accessToken = 'dev-access-token';
  static const String _refreshToken = 'dev-refresh-token';
  static const String _userId = '00000000-0000-0000-0000-000000000001';
  static const String _fullName = 'Developer';
  static const int _expiresIn = 3600;

  @override
  Future<LoginResponseDto> login({
    required String email,
    required String password,
  }) async {
    if (email != DevAuthRemoteDataSource.email ||
        password != DevAuthRemoteDataSource.password) {
      throw const ApiException(message: 'Unauthorized', statusCode: 401);
    }

    return _session;
  }

  @override
  Future<LoginResponseDto> refresh({required String refreshToken}) async {
    if (refreshToken != _refreshToken) {
      throw const ApiException(message: 'Unauthorized', statusCode: 401);
    }

    return _session;
  }

  @override
  Future<void> logout() async {}

  static const LoginResponseDto _session = LoginResponseDto(
    accessToken: _accessToken,
    refreshToken: _refreshToken,
    expiresIn: _expiresIn,
    tokenType: 'Bearer',
    userId: _userId,
    email: email,
    fullName: _fullName,
  );
}
