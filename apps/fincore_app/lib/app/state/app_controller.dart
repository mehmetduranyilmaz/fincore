import 'dart:async';

import 'package:fincore_app/app/state/app_state.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/auth/application/auth_session_manager.dart';
import 'package:fincore_app/features/auth/domain/entities/user.dart';
import 'package:fincore_app/features/auth/domain/usecases/initialize_app.dart';
import 'package:fincore_app/features/auth/domain/usecases/login_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

final class AppController extends Notifier<AppState> {
  late InitializeApp _initializeApp;
  late LoginUser _loginUser;
  late AuthSessionManager _authSessionManager;

  @override
  AppState build() {
    _initializeApp = ref.watch(initializeAppProvider);
    _loginUser = ref.watch(loginUserProvider);
    _authSessionManager = ref.watch(authSessionManagerProvider);
    final sessionEventSubscription = _authSessionManager.events.listen(
      _handleSessionEvent,
    );
    ref.onDispose(() => unawaited(sessionEventSubscription.cancel()));
    return const AppState.initializing();
  }

  Future<void> initialize() async {
    state = const AppState.initializing();

    try {
      final result = await _initializeApp.execute();

      if (result == InitializationResult.authenticated) {
        setAuthenticated();
      } else {
        setUnauthenticated();
      }
    } on Object catch (error) {
      _setFailure(error);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AppState.initializing();

    try {
      await _loginUser.execute(email: email, password: password);
      setAuthenticated();
    } on Object catch (error) {
      _setFailure(error);
    }
  }

  Future<void> logout() async {
    state = const AppState.initializing();
    await _authSessionManager.logout();
  }

  void setAuthenticated([User? currentUser]) {
    state = AppState.authenticated(currentUser: currentUser);
  }

  void setUnauthenticated() {
    state = const AppState.unauthenticated();
  }

  void _handleSessionEvent(AuthSessionEvent event) {
    if (event == AuthSessionEvent.loggedOut) {
      setUnauthenticated();
    }
  }

  void _setFailure(Object error) {
    state = AppState.failure(message: ErrorMapper.map(error));
  }
}
