import 'package:fincore_app/core/di/datasources.dart';
import 'package:fincore_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:fincore_app/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:fincore_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (ref) => AuthRepositoryImpl(
        localDataSource: ref.watch(authLocalDataSourceProvider),
        remoteDataSource: ref.watch(authRemoteDataSourceProvider),
      ),
    );

final Provider<DashboardRepository> dashboardRepositoryProvider =
    Provider<DashboardRepository>(
      (ref) => DashboardRepositoryImpl(ref.watch(dashboardDataSourceProvider)),
    );
