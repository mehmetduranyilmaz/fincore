import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';

final class LoginUser {
  const LoginUser(this._authRepository);

  final AuthRepository _authRepository;

  Future<AuthSession> execute({
    required String email,
    required String password,
  }) {
    return _authRepository.login(email: email, password: password);
  }
}
