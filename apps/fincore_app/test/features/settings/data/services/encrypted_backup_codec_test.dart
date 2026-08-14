import 'package:fincore_app/features/settings/data/services/encrypted_backup_codec.dart';
import 'package:fincore_app/features/settings/domain/errors/backup_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips encrypted financial data', () async {
    final codec = EncryptedBackupCodec();
    const data = <String, String?>{
      'accounts_v1': '[{"id":"account-1"}]',
      'transactions_v1': null,
    };

    final bytes = await codec.encrypt(
      data: data,
      password: 'güvenli-parola',
      createdAt: DateTime.utc(2026, 8, 13),
    );
    final restored = await codec.decrypt(
      bytes: bytes,
      password: 'güvenli-parola',
    );

    expect(restored, data);
    expect(String.fromCharCodes(bytes), isNot(contains('account-1')));
  });

  test('rejects a wrong password without exposing data', () async {
    final codec = EncryptedBackupCodec();
    final bytes = await codec.encrypt(
      data: const {'accounts_v1': '[]'},
      password: 'doğru-parola',
      createdAt: DateTime.utc(2026, 8, 13),
    );

    await expectLater(
      codec.decrypt(bytes: bytes, password: 'yanlış-parola'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          contains('yanlış'),
        ),
      ),
    );
  });
}
