import 'package:fincore_app/core/network/exceptions/api_exception.dart';
import 'package:fincore_app/features/auth/data/datasources/dev_auth_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const dataSource = DevAuthRemoteDataSource();

  test('returns the deterministic development session', () async {
    final response = await dataSource.login(
      email: DevAuthRemoteDataSource.email,
      password: DevAuthRemoteDataSource.password,
    );

    expect(response.accessToken, 'dev-access-token');
    expect(response.refreshToken, 'dev-refresh-token');
    expect(response.expiresIn, 3600);
    expect(response.tokenType, 'Bearer');
    expect(response.userId, '00000000-0000-0000-0000-000000000001');
    expect(response.fullName, 'Developer');
    expect(response.email, 'dev@fincore.app');
  });

  test('throws an unauthorized ApiException for invalid credentials', () async {
    await expectLater(
      dataSource.login(email: 'invalid@fincore.app', password: 'invalid'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.message, 'message', 'Unauthorized'),
      ),
    );
  });

  test(
    'returns the same session when the development token is refreshed',
    () async {
      final response = await dataSource.refresh(
        refreshToken: 'dev-refresh-token',
      );

      expect(response.accessToken, 'dev-access-token');
      expect(response.refreshToken, 'dev-refresh-token');
    },
  );
}
