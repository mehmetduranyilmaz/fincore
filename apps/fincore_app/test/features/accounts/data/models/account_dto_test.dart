import 'package:fincore_app/features/accounts/data/models/account_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads legacy records without bank metadata', () {
    final account = AccountDto.fromJson(const {
      'id': 'legacy-account',
      'name': 'Eski Hesap',
      'type': 'checking',
      'currencyCode': 'TRY',
      'isArchived': false,
      'openingBalance': 100,
    }).account;

    expect(account.bankId, isNull);
    expect(account.iban, isNull);
    expect(account.openingBalance, 100);
  });
}
