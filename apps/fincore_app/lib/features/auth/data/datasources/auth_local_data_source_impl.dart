import 'package:fincore_app/core/storage/token_storage.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';

final class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<String?> getAccessToken() {
    return _tokenStorage.getAccessToken();
  }

  @override
  Future<String?> getRefreshToken() {
    return _tokenStorage.getRefreshToken();
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    await _tokenStorage.saveRefreshToken(session.refreshToken);
    await _tokenStorage.saveAccessToken(session.accessToken);
  }

  @override
  Future<void> clearSession() {
    return _tokenStorage.clearTokens();
  }

  @override
  Future<bool> hasValidSession() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
