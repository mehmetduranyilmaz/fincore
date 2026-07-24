import 'package:fincore_app/features/auth/domain/entities/user.dart';

enum AppStatus { initializing, authenticated, unauthenticated, failure }

final class AppState {
  const AppState({
    this.status = AppStatus.initializing,
    this.currentUser,
    this.errorMessage,
  });

  const AppState.initializing() : this();

  const AppState.authenticated({User? currentUser})
    : this(status: AppStatus.authenticated, currentUser: currentUser);

  const AppState.unauthenticated() : this(status: AppStatus.unauthenticated);

  const AppState.failure({required String message})
    : this(status: AppStatus.failure, errorMessage: message);

  final AppStatus status;
  final User? currentUser;
  final String? errorMessage;
}
