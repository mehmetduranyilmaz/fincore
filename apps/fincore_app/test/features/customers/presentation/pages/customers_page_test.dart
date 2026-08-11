import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/app_shell/presentation/pages/customers_page.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows real customer balance and collection action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerRepositoryProvider.overrideWithValue(
            const _CustomerRepository(),
          ),
          transactionRepositoryProvider.overrideWithValue(
            const _TransactionRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: CustomersPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Müşteriler'), findsOneWidget);
    expect(find.text('Müşteri Ekle'), findsOneWidget);
    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('Alacağım Var: 500,00 ₺'), findsOneWidget);
    expect(find.text('Tahsilat Al'), findsOneWidget);
    expect(find.text('Ödeme Yap'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}

final class _CustomerRepository implements CustomerRepository {
  const _CustomerRepository();
  static const customer = Customer(
    id: 'customer-1',
    name: 'Acme',
    openingBalance: 500,
    currencyCode: 'TRY',
    isArchived: false,
  );

  @override
  Future<void> create(Customer customer) async {}
  @override
  Future<void> update(Customer customer) async {}
  @override
  Future<void> archive(String customerId) async {}
  @override
  Future<Customer?> getById(String customerId) async => customer;
  @override
  Future<List<Customer>> getCustomers() async => const [customer];
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository();
  @override
  Future<void> create(Transaction transaction) async {}
  @override
  Future<void> createMany(List<Transaction> transactions) async {}
  @override
  Future<Transaction?> getById(String transactionId) async => null;
  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async =>
      const [];
  @override
  Future<void> update(Transaction transaction) async {}
}
