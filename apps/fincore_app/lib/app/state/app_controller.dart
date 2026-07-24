import 'package:fincore_app/app/state/app_state.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/auth/domain/entities/user.dart';
import 'package:fincore_app/features/auth/domain/usecases/initialize_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

final class AppController extends Notifier<AppState> {
  late InitializeApp _initializeApp;

  @override
  AppState build() {
    _initializeApp = ref.watch(initializeAppProvider);
    return const AppState();
  }

  Future<void> initialize() async {
    state = const AppState();

    try {
      final result = await _initializeApp.execute();

      if (result == InitializationResult.authenticated) {
        setAuthenticated();
      } else {
        setUnauthenticated();
      }
    } on Object catch (error) {
      state = AppState(
        status: AppStatus.failure,
        errorMessage: error.toString(),
      );
    }
  }

  void logout() {
    setUnauthenticated();
  }

  void setAuthenticated([User? currentUser]) {
    state = AppState(status: AppStatus.authenticated, currentUser: currentUser);
  }

  void setUnauthenticated() {
    state = const AppState(status: AppStatus.unauthenticated);
  }
}
