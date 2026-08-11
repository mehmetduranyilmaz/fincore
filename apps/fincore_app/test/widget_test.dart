import 'package:fincore_app/app/app.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/accounts/data/datasources/account_mock_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:fincore_app/features/credit_cards/data/datasources/credit_card_mock_data_source.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:flutter/material.dart';
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

    expect(find.text('Giriş Yap'), findsOneWidget);
  });

  testWidgets('opens the app shell for authenticated users', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLocalDataSourceProvider.overrideWithValue(
            const _AuthenticatedLocalDataSource(),
          ),
          accountDataSourceProvider.overrideWithValue(
            const AccountMockDataSource(),
          ),
          creditCardDataSourceProvider.overrideWithValue(
            const CreditCardMockDataSource(),
          ),
          transactionDataSourceProvider.overrideWithValue(
            TransactionMockDataSource(),
          ),
        ],
        child: const FincoreApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fincore'), findsOneWidget);
    expect(find.text('Gösterge Paneli'), findsWidgets);
  });

  testWidgets('development credentials log in and open the app shell', (
    tester,
  ) async {
    final localDataSource = _MemoryAuthLocalDataSource();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLocalDataSourceProvider.overrideWithValue(localDataSource),
          accountDataSourceProvider.overrideWithValue(
            const AccountMockDataSource(),
          ),
          creditCardDataSourceProvider.overrideWithValue(
            const CreditCardMockDataSource(),
          ),
          transactionDataSourceProvider.overrideWithValue(
            TransactionMockDataSource(),
          ),
        ],
        child: const FincoreApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'dev@fincore.app');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();

    expect(find.text('Fincore'), findsOneWidget);
    expect(find.text('Gösterge Paneli'), findsWidgets);
    expect(localDataSource.accessToken, 'dev-access-token');
    expect(localDataSource.refreshToken, 'dev-refresh-token');
  });

  testWidgets('invalid development credentials use the existing error flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLocalDataSourceProvider.overrideWithValue(
            _MemoryAuthLocalDataSource(),
          ),
        ],
        child: const FincoreApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'invalid@fincore.app');
    await tester.enterText(find.byType(TextField).at(1), 'invalid');
    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();

    expect(find.text('Beklenmeyen bir hata oluştu.'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
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

final class _AuthenticatedLocalDataSource implements AuthLocalDataSource {
  const _AuthenticatedLocalDataSource();

  @override
  Future<void> clearSession() => Future<void>.value();

  @override
  Future<String?> getAccessToken() => Future<String?>.value('access_token');

  @override
  Future<String?> getRefreshToken() => Future<String?>.value('refresh_token');

  @override
  Future<bool> hasValidSession() => Future<bool>.value(true);

  @override
  Future<void> saveSession(AuthSession session) => Future<void>.value();
}

final class _MemoryAuthLocalDataSource implements AuthLocalDataSource {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> clearSession() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<bool> hasValidSession() async {
    return accessToken != null && accessToken!.isNotEmpty;
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    accessToken = session.accessToken;
    refreshToken = session.refreshToken;
  }
}
