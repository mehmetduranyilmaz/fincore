import 'package:fincore_app/features/auth/application/auth_session_manager.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:fincore_app/features/auth/domain/entities/user.dart';
import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logs out through the repository and publishes an event', () async {
    final repository = _AuthRepository();
    final manager = AuthSessionManager(repository);
    addTearDown(manager.dispose);
    final event = manager.events.first;

    await manager.logout();

    expect(repository.logoutCallCount, 1);
    expect(await event, AuthSessionEvent.loggedOut);
  });

  test('publishes a logout event when repository logout fails', () async {
    final repository = _AuthRepository(shouldFailLogout: true);
    final manager = AuthSessionManager(repository);
    addTearDown(manager.dispose);
    final event = manager.events.first;

    await manager.logout();

    expect(repository.logoutCallCount, 1);
    expect(await event, AuthSessionEvent.loggedOut);
  });
}

final class _AuthRepository implements AuthRepository {
  _AuthRepository({this.shouldFailLogout = false});

  final bool shouldFailLogout;
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

    if (shouldFailLogout) {
      throw Exception('Logout failed');
    }
  }

  @override
  Future<AuthSession> refresh() {
    throw UnimplementedError();
  }
}
