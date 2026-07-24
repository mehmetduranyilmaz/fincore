import 'dart:async';

import 'package:fincore_app/core/network/refresh_token_coordinator.dart';
import 'package:fincore_app/features/auth/application/auth_session_manager.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:fincore_app/features/auth/domain/entities/user.dart';
import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shares one refresh operation between concurrent callers', () async {
    final completer = Completer<String>();
    var refreshCallCount = 0;
    final coordinator = RefreshTokenCoordinator(() {
      refreshCallCount++;
      return completer.future;
    });

    final firstRefresh = coordinator.refresh();
    final secondRefresh = coordinator.refresh();

    expect(refreshCallCount, 1);
    expect(identical(firstRefresh, secondRefresh), isTrue);

    completer.complete('new_access_token');

    expect(await Future.wait([firstRefresh, secondRefresh]), [
      'new_access_token',
      'new_access_token',
    ]);
  });

  test('starts a new refresh after the active operation completes', () async {
    var refreshCallCount = 0;
    final coordinator = RefreshTokenCoordinator(() async {
      refreshCallCount++;
      return 'access_token_$refreshCallCount';
    });

    expect(await coordinator.refresh(), 'access_token_1');
    expect(await coordinator.refresh(), 'access_token_2');
    expect(refreshCallCount, 2);
  });

  test('publishes logout when refresh fails', () async {
    final repository = _AuthRepository();
    final manager = AuthSessionManager(repository);
    addTearDown(manager.dispose);
    final event = manager.events.first;
    final coordinator = RefreshTokenCoordinator(
      () => throw Exception('Refresh failed'),
      onRefreshFailure: manager.logout,
    );

    await expectLater(coordinator.refresh(), throwsException);

    expect(repository.logoutCallCount, 1);
    expect(await event, AuthSessionEvent.loggedOut);
  });
}

final class _AuthRepository implements AuthRepository {
  int logoutCallCount = 0;

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<bool> hasValidSession() async => false;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
  }

  @override
  Future<AuthSession> refresh() {
    throw UnimplementedError();
  }
}
