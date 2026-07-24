import 'package:fincore_app/features/auth/domain/entities/user.dart';

enum AppStatus { initializing, authenticated, unauthenticated, failure }

final class AppState {
  const AppState({
    this.status = AppStatus.initializing,
    this.currentUser,
    this.errorMessage,
  });

  final AppStatus status;
  final User? currentUser;
  final String? errorMessage;
}
