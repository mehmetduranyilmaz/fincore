import 'package:fincore_app/core/network/dio_provider.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => _FakeAuthLocalDataSource(),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(apiClient: ref.watch(apiClientProvider)),
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
