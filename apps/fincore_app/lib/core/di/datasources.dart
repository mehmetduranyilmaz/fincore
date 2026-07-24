import 'package:fincore_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:fincore_app/features/auth/domain/entities/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => _FakeAuthLocalDataSource(),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => const _FakeAuthRemoteDataSource(),
);

final class _FakeAuthLocalDataSource implements AuthLocalDataSource {
  AuthSession? _session;

  @override
  Future<void> clearSession() {
    _session = null;
    return Future<void>.value();
  }

  @override
  Future<bool> hasValidSession() => Future<bool>.value(_session != null);

  @override
  Future<void> saveSession(AuthSession session) {
    _session = session;
    return Future<void>.value();
  }
}

final class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  const _FakeAuthRemoteDataSource();

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return AuthSession(
      accessToken: 'demo_access_token',
      refreshToken: 'demo_refresh_token',
      user: User(id: '1', fullName: 'Demo User', email: email, isActive: true),
    );
  }

  @override
  Future<void> logout() => Future<void>.value();
}
