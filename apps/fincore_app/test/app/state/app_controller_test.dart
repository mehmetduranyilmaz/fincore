import 'package:fincore_app/app/state/app_controller.dart';
import 'package:fincore_app/app/state/app_state.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:fincore_app/features/auth/domain/entities/user.dart';
import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initialize sets unauthenticated when session is invalid', () async {
    final repository = _AuthRepository();
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).initialize();

    expect(
      container.read(appControllerProvider).status,
      AppStatus.unauthenticated,
    );
  });

  test('initialize sets authenticated when session is valid', () async {
    final repository = _AuthRepository(true);
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).initialize();

    expect(
      container.read(appControllerProvider).status,
      AppStatus.authenticated,
    );
  });

  test('login and logout update authentication status', () async {
    final repository = _AuthRepository();
    final container = _createContainer(repository);
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);

    await controller.login(email: 'demo@fincore.app', password: 'password');

    expect(
      container.read(appControllerProvider).status,
      AppStatus.authenticated,
    );

    await controller.logout();

    expect(
      container.read(appControllerProvider).status,
      AppStatus.unauthenticated,
    );
  });

  test('logout event updates authentication status', () async {
    final repository = _AuthRepository(true);
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    container.read(appControllerProvider);
    container.read(appControllerProvider.notifier).setAuthenticated();

    await container.read(authSessionManagerProvider).logout();

    expect(
      container.read(appControllerProvider).status,
      AppStatus.unauthenticated,
    );
  });
}

ProviderContainer _createContainer(AuthRepository repository) {
  return ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
}

final class _AuthRepository implements AuthRepository {
  _AuthRepository([this._hasValidSession = false]);

  bool _hasValidSession;

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<bool> hasValidSession() async => _hasValidSession;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    _hasValidSession = true;
    return AuthSession(
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
      expiresIn: 3600,
      tokenType: 'Bearer',
      userId: 'user-1',
      email: email,
      fullName: 'Demo User',
    );
  }

  @override
  Future<AuthSession> refresh() async {
    return login(email: 'demo@fincore.app', password: 'password');
  }

  @override
  Future<void> logout() async {
    _hasValidSession = false;
  }
}
