import 'package:fincore_app/core/network/dio_provider.dart';
import 'package:fincore_app/core/storage/token_storage.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_local_data_source_impl.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSourceImpl(ref.watch(tokenStorageProvider)),
);

final Provider<AuthRemoteDataSource> authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>(
      (ref) =>
          AuthRemoteDataSourceImpl(apiClient: ref.watch(apiClientProvider)),
    );
