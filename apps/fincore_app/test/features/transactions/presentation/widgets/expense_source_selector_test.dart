import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_source_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows concise source codes with descriptive names', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseSourceSelector(
            accounts: _accounts,
            creditCards: const [_creditCard],
            value: null,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(
      find.byType(DropdownButtonFormField<ExpenseSourceSelection>),
    );
    await tester.pumpAndSettle();

    expect(find.text('BK-KT-TL'), findsOneWidget);
    expect(find.text('KS-TL'), findsOneWidget);
    expect(find.text('KK-AKBANK-0349'), findsOneWidget);
    expect(find.text('Kuveyt Türk TL Hesabı'), findsOneWidget);
    expect(find.text('Ana Kasa'), findsOneWidget);
    expect(find.text('Axess'), findsOneWidget);
  });

  testWidgets('can be limited to credit cards for receipt scanning', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseSourceSelector(
            accounts: const [],
            creditCards: const [_creditCard],
            value: null,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(
      find.byType(DropdownButtonFormField<ExpenseSourceSelection>),
    );
    await tester.pumpAndSettle();

    expect(find.text('KK-AKBANK-0349'), findsOneWidget);
    expect(find.text('BK-KT-TL'), findsNothing);
    expect(find.text('KS-TL'), findsNothing);
  });
}

const _accounts = [
  Account(
    id: 'bank-account',
    name: 'Kuveyt Türk TL Hesabı',
    type: AccountType.checking,
    currencyCode: 'TRY',
    isArchived: false,
    bankId: 'kuveyt_turk',
  ),
  Account(
    id: 'cash-account',
    name: 'Ana Kasa',
    type: AccountType.cash,
    currencyCode: 'TRY',
    isArchived: false,
  ),
];

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
