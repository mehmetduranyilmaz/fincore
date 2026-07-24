import 'package:fincore_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/data/models/login_response_dto.dart';
import 'package:fincore_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps and returns the remote login response', () async {
    final localDataSource = _AuthLocalDataSource();
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: _AuthRemoteDataSource(),
    );

    final session = await repository.login(
      email: 'demo@fincore.app',
      password: 'password',
    );

    expect(
      session,
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
    expect(localDataSource.session, session);
  });

  test('refresh maps, saves, and returns the renewed session', () async {
    final localDataSource = _AuthLocalDataSource()
      ..session = const AuthSession(
        accessToken: 'expired_access_token',
        refreshToken: 'stored_refresh_token',
        expiresIn: 0,
        tokenType: 'Bearer',
        userId: 'user-1',
        email: 'demo@fincore.app',
        fullName: 'Demo User',
      );
    final remoteDataSource = _AuthRemoteDataSource();
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );

    final session = await repository.refresh();

    expect(remoteDataSource.receivedRefreshToken, 'stored_refresh_token');
    expect(session.accessToken, 'refreshed_access_token');
    expect(session.refreshToken, 'refreshed_refresh_token');
    expect(localDataSource.session, session);
  });

  test('refresh clears the local session when renewal fails', () async {
    final localDataSource = _AuthLocalDataSource()
      ..session = const AuthSession(
        accessToken: 'expired_access_token',
        refreshToken: 'stored_refresh_token',
        expiresIn: 0,
        tokenType: 'Bearer',
        userId: 'user-1',
        email: 'demo@fincore.app',
        fullName: 'Demo User',
      );
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: _AuthRemoteDataSource(failRefresh: true),
    );

    await expectLater(repository.refresh(), throwsException);

    expect(localDataSource.session, isNull);
  });
}

final class _AuthLocalDataSource implements AuthLocalDataSource {
  AuthSession? session;

  @override
  Future<void> clearSession() async {
    session = null;
  }

  @override
  Future<String?> getAccessToken() async => session?.accessToken;

  @override
  Future<String?> getRefreshToken() async => session?.refreshToken;

  @override
  Future<bool> hasValidSession() async => session != null;

  @override
  Future<void> saveSession(AuthSession session) async {
    this.session = session;
  }
}

final class _AuthRemoteDataSource implements AuthRemoteDataSource {
  _AuthRemoteDataSource({this.failRefresh = false});

  final bool failRefresh;
  String? receivedRefreshToken;

  @override
  Future<LoginResponseDto> login({
    required String email,
    required String password,
  }) async {
    return LoginResponseDto(
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
      expiresIn: 3600,
      tokenType: 'Bearer',
      userId: 'user-1',
      email: email,
      fullName: 'Demo User',
    );
  }

  @override
  Future<LoginResponseDto> refresh({required String refreshToken}) async {
    if (failRefresh) {
      throw Exception('Refresh failed');
    }

    receivedRefreshToken = refreshToken;
    return const LoginResponseDto(
      accessToken: 'refreshed_access_token',
      refreshToken: 'refreshed_refresh_token',
      expiresIn: 3600,
      tokenType: 'Bearer',
      userId: 'user-1',
      email: 'demo@fincore.app',
      fullName: 'Demo User',
    );
  }

  @override
  Future<void> logout() async {}
}
