import 'dart:async';

import 'package:fincore_app/app/state/app_state.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/auth/application/auth_session_manager.dart';
import 'package:fincore_app/features/auth/domain/entities/user.dart';
import 'package:fincore_app/features/auth/domain/usecases/initialize_app.dart';
import 'package:fincore_app/features/auth/domain/usecases/login_user.dart';
import 'package:fincore_app/features/transactions/domain/usecases/realize_due_recurring_expenses.dart';
import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

final class AppController extends Notifier<AppState> {
  late InitializeApp _initializeApp;
  late LoginUser _loginUser;
  late AuthSessionManager _authSessionManager;
  late RealizeDueRecurringExpensesUseCase _realizeDueRecurringExpenses;

  @override
  AppState build() {
    _initializeApp = ref.watch(initializeAppProvider);
    _loginUser = ref.watch(loginUserProvider);
    _authSessionManager = ref.watch(authSessionManagerProvider);
    _realizeDueRecurringExpenses = ref.watch(
      realizeDueRecurringExpensesProvider,
    );
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
        await _realizeAndRefresh();
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
      await _realizeAndRefresh();
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

  Future<void> realizeDueRecurringExpenses() async {
    if (state.status != AppStatus.authenticated) return;
    await _realizeAndRefresh();
  }

  Future<void> _realizeAndRefresh() async {
    final realized = await _realizeDueRecurringExpenses.execute();
    if (realized.isNotEmpty) {
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(current: realized);
    }
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
