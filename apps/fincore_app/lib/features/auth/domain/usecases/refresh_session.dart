import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';

final class RefreshSession {
  const RefreshSession(this._authRepository);

  final AuthRepository _authRepository;

  Future<AuthSession> execute() {
    return _authRepository.refresh();
  }
}
