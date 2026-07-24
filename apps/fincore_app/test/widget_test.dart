import 'package:fincore_app/app/app.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('redirects unauthenticated users to login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLocalDataSourceProvider.overrideWithValue(
            const _UnauthenticatedLocalDataSource(),
          ),
        ],
        child: const FincoreApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });
}

final class _UnauthenticatedLocalDataSource implements AuthLocalDataSource {
  const _UnauthenticatedLocalDataSource();

  @override
  Future<void> clearSession() => Future<void>.value();

  @override
  Future<String?> getAccessToken() => Future<String?>.value();

  @override
  Future<String?> getRefreshToken() => Future<String?>.value();

  @override
  Future<bool> hasValidSession() => Future<bool>.value(false);

  @override
  Future<void> saveSession(AuthSession session) => Future<void>.value();
}
