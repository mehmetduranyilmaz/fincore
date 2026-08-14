import 'package:fincore_app/core/network/exceptions/api_exception.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/dev_credential_store.dart';
import 'package:fincore_app/features/auth/data/models/login_response_dto.dart';

final class DevAuthRemoteDataSource implements AuthRemoteDataSource {
  const DevAuthRemoteDataSource(this._credentialStore);

  static const String email = DevCredentialStore.defaultEmail;
  static const String password = DevCredentialStore.defaultPassword;
  static const String _accessToken = 'dev-access-token';
  static const String _refreshToken = 'dev-refresh-token';
  static const String _userId = '00000000-0000-0000-0000-000000000001';
  static const String _fullName = 'Developer';
  static const int _expiresIn = 3600;

  final DevCredentialStore _credentialStore;

  @override
  Future<LoginResponseDto> login({
    required String email,
    required String password,
  }) async {
    if (!await _credentialStore.authenticate(email, password)) {
      throw const ApiException(message: 'Unauthorized', statusCode: 401);
    }

    return _session(email.trim().toLowerCase());
  }

  @override
  Future<LoginResponseDto> refresh({required String refreshToken}) async {
    if (refreshToken != _refreshToken) {
      throw const ApiException(message: 'Unauthorized', statusCode: 401);
    }

    final credentials = await _credentialStore.getOrCreate();
    return _session(credentials.email);
  }

  @override
  Future<void> logout() async {}

  static LoginResponseDto _session(String email) => LoginResponseDto(
    accessToken: _accessToken,
    refreshToken: _refreshToken,
    expiresIn: _expiresIn,
    tokenType: 'Bearer',
    userId: _userId,
    email: email,
    fullName: _fullName,
  );
}
