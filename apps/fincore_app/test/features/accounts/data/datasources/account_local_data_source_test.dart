import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/accounts/data/datasources/account_local_data_source.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('new storage starts without demo accounts', () async {
    final dataSource = AccountLocalDataSource(
      SecureStorageService(const FlutterSecureStorage()),
    );

    expect(await dataSource.getAccounts(), isEmpty);
  });

  test('persists bank and normalized IBAN across instances', () async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final firstDataSource = AccountLocalDataSource(storage);
    await firstDataSource.insert(_account);

    final secondDataSource = AccountLocalDataSource(storage);
    final persisted = await secondDataSource.getById(_account.id);

    expect(persisted, _account);
    expect(persisted?.bankId, 'kuveyt_turk');
    expect(persisted?.iban, 'TR330006100519786457841326');
  });
}

const _account = Account(
  id: 'account-user-1',
  name: 'Kuveyt Türk TL Hesabı',
  type: AccountType.checking,
  currencyCode: 'TRY',
  isArchived: false,
  openingBalance: 12500.75,
  bankId: 'kuveyt_turk',
  iban: 'TR330006100519786457841326',
);
