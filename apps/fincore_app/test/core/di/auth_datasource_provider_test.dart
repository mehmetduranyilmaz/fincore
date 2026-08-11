import 'package:fincore_app/core/config/environment.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/network/dio_provider.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:fincore_app/features/auth/data/datasources/dev_auth_remote_data_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects the development datasource in the dev environment', () {
    final container = ProviderContainer(
      overrides: [environmentProvider.overrideWithValue(Environment.dev)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(authRemoteDataSourceProvider),
      isA<DevAuthRemoteDataSource>(),
    );
  });

  test('keeps the existing API datasource in the production environment', () {
    final container = ProviderContainer(
      overrides: [environmentProvider.overrideWithValue(Environment.prod)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(authRemoteDataSourceProvider),
      isA<AuthRemoteDataSourceImpl>(),
    );
  });
}
