import 'package:fincore_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/data/mappers/login_response_dto_mapper.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:fincore_app/features/auth/domain/entities/user.dart';
import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<User?> getCurrentUser() => throw UnimplementedError();

  @override
  Future<bool> hasValidSession() => localDataSource.hasValidSession();

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await remoteDataSource.login(
      email: email,
      password: password,
    );
    final session = response.toEntity();

    await localDataSource.saveSession(session);

    return session;
  }

  @override
  Future<AuthSession> refresh() async {
    try {
      final refreshToken = await localDataSource.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        throw StateError('Refresh token is unavailable');
      }

      final response = await remoteDataSource.refresh(
        refreshToken: refreshToken,
      );
      final session = response.toEntity();

      await localDataSource.saveSession(session);

      return session;
    } on Object {
      await localDataSource.clearSession();
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } finally {
      await localDataSource.clearSession();
    }
  }
}
