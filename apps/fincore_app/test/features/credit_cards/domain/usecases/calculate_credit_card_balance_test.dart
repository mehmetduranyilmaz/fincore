import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_balance.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/calculate_credit_card_balance.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('derives card debt, spending, payments, and available limit', () async {
    final useCase = CalculateCreditCardBalanceUseCase(
      const _CreditCardRepository([_creditCard]),
      _TransactionRepository([
        _transaction(
          id: 'expense',
          amount: 3000,
          type: TransactionType.expense,
        ),
        _transaction(id: 'payment', amount: 1000, type: TransactionType.income),
        _transaction(
          id: 'transfer',
          amount: 500,
          type: TransactionType.transfer,
        ),
        _transaction(
          id: 'deleted-expense',
          amount: 500,
          type: TransactionType.expense,
          isDeleted: true,
        ),
        _transaction(
          id: 'other-card',
          creditCardId: 'credit-card-2',
          amount: 900,
          type: TransactionType.expense,
        ),
      ]),
    );

    final result = await useCase.execute('credit-card-1');

    expect(
      result,
      CreditCardBalance(
        creditLimit: 10000,
        currentDebt: 2000,
        totalSpent: 3000,
        totalPayments: 1000,
      ),
    );
    expect(result.availableLimit, 8000);
  });

  test('never returns a negative available limit', () async {
    final useCase = CalculateCreditCardBalanceUseCase(
      const _CreditCardRepository([_creditCard]),
      _TransactionRepository([
        _transaction(
          id: 'over-limit',
          amount: 12000,
          type: TransactionType.expense,
        ),
      ]),
    );

    final result = await useCase.execute('credit-card-1');

    expect(result.currentDebt, 12000);
    expect(result.availableLimit, 0);
  });
}

const CreditCard _creditCard = CreditCard(
  id: 'credit-card-1',
  bankName: 'Test Bank',
  cardName: 'Test Card',
  lastFourDigits: '1111',
  creditLimit: 10000,
  statementDay: 10,
  dueDay: 20,
  currencyCode: 'TRY',
  isArchived: false,
);

Transaction _transaction({
  required String id,
  String creditCardId = 'credit-card-1',
  required double amount,
  required TransactionType type,
  bool isDeleted = false,
}) {
  return Transaction(
    id: id,
    accountId: null,
    creditCardId: creditCardId,
    amount: amount,
    transactionType: type,
    categoryId: null,
    merchant: id,
    note: null,
    transactionDate: DateTime(2026, 7, 25),
    source: TransactionSource.import,
    isDeleted: isDeleted,
    transferGroupId: type == TransactionType.transfer ? 'group-$id' : null,
  );
}

final class _CreditCardRepository implements CreditCardRepository {
  const _CreditCardRepository(this.creditCards);

  final List<CreditCard> creditCards;

  @override
  Future<List<CreditCard>> getCreditCards() async => creditCards;
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.transactions);

  final List<Transaction> transactions;

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    return transactions;
  }

  @override
  Future<void> update(Transaction transaction) async {}
}
