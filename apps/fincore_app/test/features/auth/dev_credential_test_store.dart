import 'package:cryptography/cryptography.dart';
import 'package:fincore_app/features/auth/data/datasources/dev_auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/dev_credential_store.dart';

final class MemoryCredentialKeyValueStore implements CredentialKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

DevCredentialStore createDevCredentialStore() {
  return DevCredentialStore(
    MemoryCredentialKeyValueStore(),
    passwordHasher: Pbkdf2.hmacSha256(iterations: 1, bits: 256),
  );
}

DevAuthRemoteDataSource createDevAuthRemoteDataSource() {
  return DevAuthRemoteDataSource(createDevCredentialStore());
}
