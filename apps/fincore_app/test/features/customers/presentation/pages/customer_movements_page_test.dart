import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/entities/customer_movement.dart';
import 'package:fincore_app/features/customers/presentation/pages/customer_movements_page.dart';
import 'package:fincore_app/features/customers/presentation/providers/customer_balance_provider.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows debtor and creditor codes beside each running balance', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 700);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerProvider.overrideWith((ref, id) async => _customer),
          customerMovementsProvider.overrideWith((ref, id) async => _movements),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CustomerMovementsPage(customerId: 'customer-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bakiye: 20,00 ₺ B'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Bakiye: 50,00 ₺ A'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bakiye: 50,00 ₺ A'), findsOneWidget);
  });
}

const _customer = Customer(
  id: 'customer-1',
  name: 'Acme',
  openingBalance: 100,
  currencyCode: 'TRY',
  isArchived: false,
);

final _movements = [
  CustomerMovement(
    transaction: _transaction('payment', 70),
    balanceAfterMovement: 20,
  ),
  CustomerMovement(
    transaction: _transaction('collection', -150),
    balanceAfterMovement: -50,
  ),
];

Transaction _transaction(String id, double delta) {
  return Transaction(
    id: id,
    accountId: 'account-1',
    creditCardId: null,
    amount: delta.abs(),
    transactionType: TransactionType.transfer,
    categoryId: null,
    merchant: id,
    note: null,
    transactionDate: DateTime(2026, 8, 1),
    source: TransactionSource.manual,
    isDeleted: false,
    paymentGroupId: 'group-$id',
    customerId: 'customer-1',
    customerBalanceDelta: delta,
  );
}
