import 'package:fincore_app/features/auth/domain/entities/update_user_credentials_input.dart';
import 'package:fincore_app/features/auth/domain/entities/user_credentials_profile.dart';
import 'package:fincore_app/features/auth/domain/errors/user_credentials_exception.dart';
import 'package:fincore_app/features/auth/domain/repositories/user_credentials_repository.dart';
import 'package:fincore_app/features/auth/domain/usecases/update_user_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes email and passes valid credentials to repository', () async {
    final repository = _Repository();
    final useCase = UpdateUserCredentials(repository);

    final result = await useCase.execute(
      const UpdateUserCredentialsInput(
        currentPassword: 'current-password',
        newEmail: '  Mehmet@Example.COM ',
        newPassword: 'new-password',
      ),
    );

    expect(result.email, 'mehmet@example.com');
    expect(repository.received!.newEmail, 'mehmet@example.com');
  });

  test('rejects invalid email and short optional password', () async {
    final useCase = UpdateUserCredentials(_Repository());

    await expectLater(
      useCase.execute(
        const UpdateUserCredentialsInput(
          currentPassword: 'current-password',
          newEmail: 'invalid',
          newPassword: null,
        ),
      ),
      throwsA(isA<UserCredentialsException>()),
    );
    await expectLater(
      useCase.execute(
        const UpdateUserCredentialsInput(
          currentPassword: 'current-password',
          newEmail: 'mehmet@example.com',
          newPassword: 'short',
        ),
      ),
      throwsA(isA<UserCredentialsException>()),
    );
  });
}

final class _Repository implements UserCredentialsRepository {
  UpdateUserCredentialsInput? received;

  @override
  Future<UserCredentialsProfile> getProfile() async =>
      const UserCredentialsProfile(email: 'dev@fincore.app');

  @override
  Future<UserCredentialsProfile> update(
    UpdateUserCredentialsInput input,
  ) async {
    received = input;
    return UserCredentialsProfile(email: input.newEmail);
  }
}
