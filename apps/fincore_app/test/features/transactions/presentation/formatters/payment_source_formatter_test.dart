import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/transactions/presentation/formatters/payment_source_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats bank account, cash and credit card source codes', () {
    expect(
      PaymentSourceFormatter.account(
        const Account(
          id: 'bank-account',
          name: 'Kuveyt Türk TL Hesabı',
          type: AccountType.checking,
          currencyCode: 'TRY',
          isArchived: false,
          bankId: 'kuveyt_turk',
        ),
      ),
      'BK-KT-TL',
    );
    expect(
      PaymentSourceFormatter.account(
        const Account(
          id: 'cash-account',
          name: 'TL Kasası',
          type: AccountType.cash,
          currencyCode: 'TRY',
          isArchived: false,
        ),
      ),
      'KS-TL',
    );
    expect(PaymentSourceFormatter.creditCard(_creditCard), 'KK-AKBANK-0349');
  });
}

const _creditCard = CreditCard(
  id: 'card-1',
  bankName: 'Akbank',
  cardName: 'Axess',
  lastFourDigits: '0349',
  creditLimit: 10000,
  statementDay: 20,
  dueDay: 30,
  currencyCode: 'TRY',
  isArchived: false,
);
