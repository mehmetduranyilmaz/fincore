import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:fincore_app/features/auth/domain/services/silent_session_validator.dart';

enum InitializationResult { authenticated, unauthenticated }

final class InitializeApp {
  const InitializeApp(this._authRepository, [this._silentSessionValidator]);

  final AuthRepository _authRepository;
  final SilentSessionValidator? _silentSessionValidator;

  Future<InitializationResult> execute() async {
    final hasValidSession = await _authRepository.hasValidSession();

    if (!hasValidSession) {
      return InitializationResult.unauthenticated;
    }

    final silentSessionValidator = _silentSessionValidator;

    if (silentSessionValidator == null) {
      return InitializationResult.authenticated;
    }

    final isSessionValid = await silentSessionValidator.validate();

    return isSessionValid
        ? InitializationResult.authenticated
        : InitializationResult.unauthenticated;
  }
}
