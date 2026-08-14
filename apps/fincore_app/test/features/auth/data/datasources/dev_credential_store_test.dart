import 'package:fincore_app/features/auth/data/datasources/dev_credential_store.dart';
import 'package:fincore_app/features/auth/domain/errors/user_credentials_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates defaults without storing the plain-text password', () async {
    final storage = _MemoryStore();
    final store = DevCredentialStore(storage);

    final record = await store.getOrCreate();

    expect(record.email, DevCredentialStore.defaultEmail);
    expect(
      await store.authenticate(
        DevCredentialStore.defaultEmail,
        DevCredentialStore.defaultPassword,
      ),
      isTrue,
    );
    expect(storage.values.values.single, isNot(contains('123456')));
  });

  test('updates email and password after verifying current password', () async {
    final store = DevCredentialStore(_MemoryStore());
    await store.getOrCreate();

    final result = await store.update(
      currentPassword: DevCredentialStore.defaultPassword,
      newEmail: 'mehmet@example.com',
      newPassword: 'YeniGuvenli123',
    );

    expect(result.email, 'mehmet@example.com');
    expect(
      await store.authenticate('mehmet@example.com', 'YeniGuvenli123'),
      isTrue,
    );
    expect(
      await store.authenticate(
        DevCredentialStore.defaultEmail,
        DevCredentialStore.defaultPassword,
      ),
      isFalse,
    );
  });

  test('does not change credentials when current password is wrong', () async {
    final store = DevCredentialStore(_MemoryStore());

    await expectLater(
      store.update(
        currentPassword: 'yanlış',
        newEmail: 'mehmet@example.com',
        newPassword: 'YeniGuvenli123',
      ),
      throwsA(isA<UserCredentialsException>()),
    );
    expect(
      await store.authenticate(
        DevCredentialStore.defaultEmail,
        DevCredentialStore.defaultPassword,
      ),
      isTrue,
    );
  });
}

final class _MemoryStore implements CredentialKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
