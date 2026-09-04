import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/domain/usecases/calculate_account_balance.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/calculate_credit_card_balance.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_statement_payment_status.dart';
import 'package:fincore_app/features/customers/domain/entities/credit_card_payment_input.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/entities/customer_payment_input.dart';
import 'package:fincore_app/features/customers/domain/entities/update_customer_payment_input.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/customers/domain/usecases/calculate_customer_balance.dart';
import 'package:fincore_app/features/customers/domain/usecases/create_credit_card_payment.dart';
import 'package:fincore_app/features/customers/domain/usecases/create_customer_payment.dart';
import 'package:fincore_app/features/customers/domain/usecases/update_customer_payment.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _TransactionRepository transactions;
  late CalculateAccountBalanceUseCase accountBalance;
  late CalculateCreditCardBalanceUseCase cardBalance;

  setUp(() {
    transactions = _TransactionRepository([
      _transaction(
        id: 'account-income',
        accountId: _account.id,
        amount: 1000,
        type: TransactionType.income,
      ),
      _transaction(
        id: 'card-expense',
        creditCardId: _card.id,
        amount: 500,
        type: TransactionType.expense,
      ),
    ]);
    accountBalance = CalculateAccountBalanceUseCase(transactions);
    cardBalance = CalculateCreditCardBalanceUseCase(
      const _CreditCardRepository(),
      transactions,
    );
  });

  test(
    'credit card payment decreases account and card debt together',
    () async {
      final useCase = CreateCreditCardPaymentUseCase(
        transactions,
        const _AccountRepository(),
        const _CreditCardRepository(),
        const _CreditCardStatementRepository(),
        accountBalance,
        cardBalance,
        clock: () => DateTime(2026, 8, 7),
        idGenerator: (index) => 'payment-$index',
        groupIdGenerator: () => 'payment-group',
      );

      await useCase.execute(
        CreditCardPaymentInput(
          creditCardId: _card.id,
          fromAccountId: _account.id,
          amount: 200,
          description: '',
          paymentDate: DateTime(2026, 8, 7),
        ),
      );

      expect((await accountBalance.execute(_account.id)).currentBalance, 800);
      final updatedCard = await cardBalance.execute(_card.id);
      expect(updatedCard.currentDebt, 300);
      expect(updatedCard.availableLimit, 9700);
      expect(
        transactions.items.where(
          (item) => item.paymentGroupId == 'payment-group',
        ),
        hasLength(2),
      );
    },
  );

  test('statement payment tracks the remaining statement debt', () async {
    final statement = CreditCardStatement(
      id: 'statement-1',
      creditCardId: _card.id,
      statementDate: DateTime(2026, 8, 5),
      dueDate: DateTime(2026, 8, 20),
      lines: [
        CreditCardStatementLine(
          transactionId: 'card-expense',
          description: 'Ekstre harcaması',
          transactionDate: DateTime(2026, 8, 1),
          amount: 300,
        ),
      ],
      createdAt: DateTime(2026, 8, 5),
    );
    final statementRepository = _CreditCardStatementRepository([statement]);
    final useCase = CreateCreditCardPaymentUseCase(
      transactions,
      const _AccountRepository(),
      const _CreditCardRepository(),
      statementRepository,
      accountBalance,
      cardBalance,
      clock: () => DateTime(2026, 8, 7),
      idGenerator: (index) => 'statement-payment-$index',
      groupIdGenerator: () => 'statement-payment-group',
    );

    final created = await useCase.execute(
      CreditCardPaymentInput(
        creditCardId: _card.id,
        fromAccountId: _account.id,
        amount: 200,
        description: '',
        paymentDate: DateTime(2026, 8, 7),
        statementId: statement.id,
      ),
    );

    expect(created, everyElement(hasStatementId(statement.id)));
    expect((await accountBalance.execute(_account.id)).currentBalance, 800);
    expect((await cardBalance.execute(_card.id)).currentDebt, 300);
    final status = await GetCreditCardStatementPaymentStatusUseCase(
      statementRepository,
      transactions,
    ).execute(creditCardId: _card.id, statementId: statement.id);
    expect(status.paidAmount, 200);
    expect(status.remainingAmount, 100);
    expect(status.isPaid, isFalse);
  });

  test('allows collection even when customer is currently payable', () async {
    const customer = Customer(
      id: 'customer-advance',
      name: 'Avans Müşterisi',
      openingBalance: -100,
      currencyCode: 'TRY',
      isArchived: false,
    );
    final customerRepository = _CustomerRepository(customer);
    final customerBalance = CalculateCustomerBalanceUseCase(
      customerRepository,
      transactions,
    );
    final useCase = CreateCustomerPaymentUseCase(
      transactions,
      customerRepository,
      const _AccountRepository(),
      const _CreditCardRepository(),
      accountBalance,
      cardBalance,
      clock: () => DateTime(2026, 8, 7),
      idGenerator: (_) => 'advance-collection',
      groupIdGenerator: () => 'advance-collection-group',
    );

    await useCase.execute(
      CustomerPaymentInput(
        customerId: customer.id,
        direction: CustomerPaymentDirection.collect,
        accountId: _account.id,
        creditCardId: null,
        amount: 150,
        description: '',
        paymentDate: DateTime(2026, 8, 7),
      ),
    );

    expect(await customerBalance.execute(customer.id), -250);
    expect((await accountBalance.execute(_account.id)).currentBalance, 1150);
  });

  test('allows payment even when customer is currently receivable', () async {
    const customer = Customer(
      id: 'customer-prepayment',
      name: 'Ön Ödeme Müşterisi',
      openingBalance: 100,
      currencyCode: 'TRY',
      isArchived: false,
    );
    final customerRepository = _CustomerRepository(customer);
    final customerBalance = CalculateCustomerBalanceUseCase(
      customerRepository,
      transactions,
    );
    final useCase = CreateCustomerPaymentUseCase(
      transactions,
      customerRepository,
      const _AccountRepository(),
      const _CreditCardRepository(),
      accountBalance,
      cardBalance,
      clock: () => DateTime(2026, 8, 7),
      idGenerator: (_) => 'prepayment',
      groupIdGenerator: () => 'prepayment-group',
    );

    await useCase.execute(
      CustomerPaymentInput(
        customerId: customer.id,
        direction: CustomerPaymentDirection.pay,
        accountId: _account.id,
        creditCardId: null,
        amount: 150,
        description: '',
        paymentDate: DateTime(2026, 8, 7),
      ),
    );

    expect(await customerBalance.execute(customer.id), 250);
    expect((await accountBalance.execute(_account.id)).currentBalance, 850);
  });

  test('updates a customer payment and recalculates both ledgers', () async {
    const customer = Customer(
      id: 'customer-edit',
      name: 'Düzenlenen Müşteri',
      openingBalance: -300,
      currencyCode: 'TRY',
      isArchived: false,
    );
    final customerRepository = _CustomerRepository(customer);
    final create = CreateCustomerPaymentUseCase(
      transactions,
      customerRepository,
      const _AccountRepository(),
      const _CreditCardRepository(),
      accountBalance,
      cardBalance,
      clock: () => DateTime(2026, 8, 7),
      idGenerator: (_) => 'editable-payment',
      groupIdGenerator: () => 'editable-payment-group',
    );
    await create.execute(
      CustomerPaymentInput(
        customerId: customer.id,
        direction: CustomerPaymentDirection.pay,
        accountId: _account.id,
        creditCardId: null,
        amount: 100,
        description: 'İlk ödeme',
        paymentDate: DateTime(2026, 8, 6),
      ),
    );
    final update = UpdateCustomerPaymentUseCase(
      transactions,
      customerRepository,
      const _AccountRepository(),
      const _CreditCardRepository(),
      accountBalance,
      cardBalance,
    );

    await update.execute(
      UpdateCustomerPaymentInput(
        transactionId: 'editable-payment',
        accountId: _account.id,
        creditCardId: null,
        amount: 200,
        description: 'Düzeltilmiş ödeme',
        paymentDate: DateTime(2026, 8, 7),
      ),
    );

    final customerBalance = CalculateCustomerBalanceUseCase(
      customerRepository,
      transactions,
    );
    expect(await customerBalance.execute(customer.id), -100);
    expect((await accountBalance.execute(_account.id)).currentBalance, 800);
    expect(
      (await transactions.getById('editable-payment'))!.merchant,
      'Düzeltilmiş ödeme',
    );
  });

  test(
    'customer collection increases account and decreases receivable',
    () async {
      const customer = Customer(
        id: 'customer-1',
        name: 'Müşteri',
        openingBalance: 400,
        currencyCode: 'TRY',
        isArchived: false,
      );
      final customerRepository = _CustomerRepository(customer);
      final customerBalance = CalculateCustomerBalanceUseCase(
        customerRepository,
        transactions,
      );
      final useCase = CreateCustomerPaymentUseCase(
        transactions,
        customerRepository,
        const _AccountRepository(),
        const _CreditCardRepository(),
        accountBalance,
        cardBalance,
        clock: () => DateTime(2026, 8, 7),
        idGenerator: (_) => 'collection',
        groupIdGenerator: () => 'collection-group',
      );

      await useCase.execute(
        CustomerPaymentInput(
          customerId: customer.id,
          direction: CustomerPaymentDirection.collect,
          accountId: _account.id,
          creditCardId: null,
          amount: 150,
          description: '',
          paymentDate: DateTime(2026, 8, 7),
        ),
      );

      expect(await customerBalance.execute(customer.id), 250);
      expect((await accountBalance.execute(_account.id)).currentBalance, 1150);
    },
  );

  test(
    'customer payment by card reduces payable and consumes card limit',
    () async {
      const customer = Customer(
        id: 'customer-2',
        name: 'Tedarikçi',
        openingBalance: -300,
        currencyCode: 'TRY',
        isArchived: false,
      );
      final customerRepository = _CustomerRepository(customer);
      final customerBalance = CalculateCustomerBalanceUseCase(
        customerRepository,
        transactions,
      );
      final useCase = CreateCustomerPaymentUseCase(
        transactions,
        customerRepository,
        const _AccountRepository(),
        const _CreditCardRepository(),
        accountBalance,
        cardBalance,
        clock: () => DateTime(2026, 8, 7),
        idGenerator: (_) => 'customer-card-payment',
        groupIdGenerator: () => 'customer-card-group',
      );

      await useCase.execute(
        CustomerPaymentInput(
          customerId: customer.id,
          direction: CustomerPaymentDirection.pay,
          accountId: null,
          creditCardId: _card.id,
          amount: 100,
          description: '',
          paymentDate: DateTime(2026, 8, 7),
        ),
      );

      expect(await customerBalance.execute(customer.id), -200);
      expect((await cardBalance.execute(_card.id)).currentDebt, 600);
    },
  );

  test(
    'customer card installments create one dated customer row per due date',
    () async {
      const customer = Customer(
        id: 'customer-installment',
        name: 'Cuma Burak Yılmaz',
        openingBalance: -3000,
        currencyCode: 'TRY',
        isArchived: false,
      );
      final useCase = CreateCustomerPaymentUseCase(
        transactions,
        const _CustomerRepository(customer),
        const _AccountRepository(),
        const _CreditCardRepository(),
        accountBalance,
        cardBalance,
        clock: () => DateTime(2026, 9, 3),
        idGenerator: (index) => 'customer-installment-$index',
        groupIdGenerator: () => 'customer-installment-group',
      );

      await useCase.execute(
        CustomerPaymentInput(
          customerId: customer.id,
          direction: CustomerPaymentDirection.pay,
          accountId: null,
          creditCardId: _card.id,
          amount: 3000,
          description: 'FLO',
          paymentDate: DateTime(2026, 9, 3),
          installmentAmounts: const [1000, 1000, 1000],
        ),
      );

      final rows = transactions.items
          .where((item) => item.installmentPlanId != null)
          .toList();
      expect(rows.map((item) => item.transactionDate), [
        DateTime(2026, 9, 3),
        DateTime(2026, 10, 3),
        DateTime(2026, 11, 3),
      ]);
      expect(rows.map((item) => item.amount), [1000, 1000, 1000]);
      expect(rows.map((item) => item.merchant), [
        'FLO 1/3 03.09.26',
        'FLO 2/3 03.09.26',
        'FLO 3/3 03.09.26',
      ]);
      expect(rows.map((item) => item.customerBalanceDelta), [1000, 1000, 1000]);
    },
  );
}

const _account = Account(
  id: 'account-1',
  name: 'Banka',
  type: AccountType.checking,
  currencyCode: 'TRY',
  isArchived: false,
);

const _card = CreditCard(
  id: 'card-1',
  bankName: 'Banka',
  cardName: 'Kart',
  lastFourDigits: '1234',
  creditLimit: 10000,
  statementDay: 10,
  dueDay: 20,
  currencyCode: 'TRY',
  isArchived: false,
);

Transaction _transaction({
  required String id,
  String? accountId,
  String? creditCardId,
  required double amount,
  required TransactionType type,
}) {
  return Transaction(
    id: id,
    accountId: accountId,
    creditCardId: creditCardId,
    amount: amount,
    transactionType: type,
    categoryId: null,
    merchant: id,
    note: null,
    transactionDate: DateTime(2026, 8, 1),
    source: TransactionSource.manual,
    isDeleted: false,
  );
}

final class _TransactionRepository implements TransactionRepository {
  _TransactionRepository(this.items);
  final List<Transaction> items;

  @override
  Future<void> create(Transaction transaction) async => items.add(transaction);
  @override
  Future<void> createMany(List<Transaction> transactions) async =>
      items.addAll(transactions);
  @override
  Future<Transaction?> getById(String transactionId) async =>
      items.where((item) => item.id == transactionId).firstOrNull;
  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async =>
      items.where((item) {
        if (filter.accountId != null && item.accountId != filter.accountId) {
          return false;
        }
        if (filter.creditCardId != null &&
            item.creditCardId != filter.creditCardId) {
          return false;
        }
        return !item.isDeleted;
      }).toList();
  @override
  Future<void> update(Transaction transaction) async {
    final index = items.indexWhere((item) => item.id == transaction.id);
    items[index] = transaction;
  }
}

final class _AccountRepository implements AccountRepository {
  const _AccountRepository();
  @override
  Future<List<Account>> getAccounts() async => const [_account];
}

final class _CreditCardRepository implements CreditCardRepository {
  const _CreditCardRepository();
  @override
  Future<List<CreditCard>> getCreditCards() async => const [_card];
}

final class _CreditCardStatementRepository
    implements CreditCardStatementRepository {
  const _CreditCardStatementRepository([
    this.statements = const <CreditCardStatement>[],
  ]);

  final List<CreditCardStatement> statements;

  @override
  Future<void> create(CreditCardStatement statement) async {}

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(
    String creditCardId,
  ) async => statements
      .where((statement) => statement.creditCardId == creditCardId)
      .toList(growable: false);
}

Matcher hasStatementId(String statementId) => predicate<Transaction>(
  (transaction) => transaction.creditCardStatementId == statementId,
  'has statement id $statementId',
);

final class _CustomerRepository implements CustomerRepository {
  const _CustomerRepository(this.customer);
  final Customer customer;
  @override
  Future<void> create(Customer customer) async {}
  @override
  Future<void> update(Customer customer) async {}
  @override
  Future<void> archive(String customerId) async {}
  @override
  Future<Customer?> getById(String customerId) async =>
      customer.id == customerId ? customer : null;
  @override
  Future<List<Customer>> getCustomers() async => [customer];
}
