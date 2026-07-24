import 'package:fincore_app/core/di/datasources.dart';
import 'package:fincore_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    localDataSource: ref.watch(authLocalDataSourceProvider),
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  ),
);
