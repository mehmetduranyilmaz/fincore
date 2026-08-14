import 'package:fincore_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/dev_auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../dev_credential_test_store.dart';

void main() {
  test(
    'persists development tokens through the existing repository flow',
    () async {
      final localDataSource = _MemoryAuthLocalDataSource();
      final repository = AuthRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: createDevAuthRemoteDataSource(),
      );

      final session = await repository.login(
        email: DevAuthRemoteDataSource.email,
        password: DevAuthRemoteDataSource.password,
      );

      expect(localDataSource.accessToken, 'dev-access-token');
      expect(localDataSource.refreshToken, 'dev-refresh-token');
      expect(localDataSource.savedSession, session);
    },
  );

  test('logout clears the persisted development tokens', () async {
    final localDataSource = _MemoryAuthLocalDataSource();
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: createDevAuthRemoteDataSource(),
    );

    await repository.login(
      email: DevAuthRemoteDataSource.email,
      password: DevAuthRemoteDataSource.password,
    );
    await repository.logout();

    expect(localDataSource.accessToken, isNull);
    expect(localDataSource.refreshToken, isNull);
    expect(localDataSource.clearCount, 1);
  });
}

final class _MemoryAuthLocalDataSource implements AuthLocalDataSource {
  String? accessToken;
  String? refreshToken;
  AuthSession? savedSession;
  int clearCount = 0;

  @override
  Future<void> clearSession() async {
    accessToken = null;
    refreshToken = null;
    savedSession = null;
    clearCount++;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<bool> hasValidSession() async {
    return accessToken != null && accessToken!.isNotEmpty;
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    accessToken = session.accessToken;
    refreshToken = session.refreshToken;
    savedSession = session;
  }
}
