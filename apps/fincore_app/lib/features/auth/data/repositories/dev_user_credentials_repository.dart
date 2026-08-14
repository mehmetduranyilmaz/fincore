import 'package:fincore_app/features/auth/data/datasources/dev_credential_store.dart';
import 'package:fincore_app/features/auth/domain/entities/update_user_credentials_input.dart';
import 'package:fincore_app/features/auth/domain/entities/user_credentials_profile.dart';
import 'package:fincore_app/features/auth/domain/repositories/user_credentials_repository.dart';

final class DevUserCredentialsRepository implements UserCredentialsRepository {
  const DevUserCredentialsRepository(this._store);

  final DevCredentialStore _store;

  @override
  Future<UserCredentialsProfile> getProfile() async {
    final record = await _store.getOrCreate();
    return UserCredentialsProfile(email: record.email);
  }

  @override
  Future<UserCredentialsProfile> update(
    UpdateUserCredentialsInput input,
  ) async {
    final record = await _store.update(
      currentPassword: input.currentPassword,
      newEmail: input.newEmail,
      newPassword: input.newPassword,
    );
    return UserCredentialsProfile(email: record.email);
  }
}
