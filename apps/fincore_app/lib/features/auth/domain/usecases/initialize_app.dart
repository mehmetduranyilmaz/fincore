import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';

enum InitializationResult { authenticated, unauthenticated }

final class InitializeApp {
  const InitializeApp(this._authRepository);

  final AuthRepository _authRepository;

  Future<InitializationResult> execute() async {
    final hasValidSession = await _authRepository.hasValidSession();

    return hasValidSession
        ? InitializationResult.authenticated
        : InitializationResult.unauthenticated;
  }
}
