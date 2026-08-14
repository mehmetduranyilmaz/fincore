import 'package:fincore_app/features/auth/domain/entities/update_user_credentials_input.dart';
import 'package:fincore_app/features/auth/domain/entities/user_credentials_profile.dart';
import 'package:fincore_app/features/auth/domain/errors/user_credentials_exception.dart';
import 'package:fincore_app/features/auth/domain/repositories/user_credentials_repository.dart';

final class UpdateUserCredentials {
  const UpdateUserCredentials(this._repository);

  final UserCredentialsRepository _repository;

  Future<UserCredentialsProfile> execute(
    UpdateUserCredentialsInput input,
  ) async {
    final email = input.newEmail.trim().toLowerCase();
    if (!_emailPattern.hasMatch(email)) {
      throw const UserCredentialsException('Geçerli bir e-posta girin.');
    }
    if (input.currentPassword.isEmpty) {
      throw const UserCredentialsException('Mevcut şifrenizi girin.');
    }
    final newPassword = input.newPassword;
    if (newPassword != null && newPassword.length < 8) {
      throw const UserCredentialsException(
        'Yeni şifre en az 8 karakter olmalıdır.',
      );
    }
    return _repository.update(
      UpdateUserCredentialsInput(
        currentPassword: input.currentPassword,
        newEmail: email,
        newPassword: newPassword,
      ),
    );
  }

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
}
