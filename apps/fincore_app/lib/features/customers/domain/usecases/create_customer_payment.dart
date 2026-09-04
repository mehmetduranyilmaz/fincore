import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/domain/usecases/calculate_account_balance.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/calculate_credit_card_balance.dart';
import 'package:fincore_app/features/customers/domain/entities/customer_payment_input.dart';
import 'package:fincore_app/features/customers/domain/errors/customer_operation_exception.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/customers/domain/usecases/create_credit_card_payment.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/installment_calculator.dart';

final class CreateCustomerPaymentUseCase {
  CreateCustomerPaymentUseCase(
    this._transactionRepository,
    this._customerRepository,
    this._accountRepository,
    this._creditCardRepository,
    this._calculateAccountBalance,
    this._calculateCreditCardBalance, {
    PaymentClock? clock,
    PaymentIdGenerator? idGenerator,
    PaymentGroupIdGenerator? groupIdGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _generateId,
       _groupIdGenerator = groupIdGenerator ?? _generateGroupId;

  final TransactionRepository _transactionRepository;
  final CustomerRepository _customerRepository;
  final AccountRepository _accountRepository;
  final CreditCardRepository _creditCardRepository;
  final CalculateAccountBalanceUseCase _calculateAccountBalance;
  final CalculateCreditCardBalanceUseCase _calculateCreditCardBalance;
  final PaymentClock _clock;
  final PaymentIdGenerator _idGenerator;
  final PaymentGroupIdGenerator _groupIdGenerator;

  Future<Transaction> execute(CustomerPaymentInput input) async {
    _validateShape(input);
    final customer = await _customerRepository.getById(input.customerId);
    if (customer == null || customer.isArchived) {
      throw const CustomerOperationException('Müşteri bulunamadı.');
    }
    await _validatePaymentSource(input, customer.currencyCode);

    final isCollection = input.direction == CustomerPaymentDirection.collect;
    final description = input.description.trim().isEmpty
        ? '${isCollection ? 'Tahsilat' : 'Ödeme'} - ${customer.name}'
        : input.description.trim();
    final installmentAmounts = input.installmentAmounts.length > 1
        ? input.installmentAmounts
        : [input.amount];
    if (installmentAmounts.length > 1) {
      if (input.creditCardId == null) {
        throw ArgumentError('Installments require a credit card.');
      }
      InstallmentCalculator.validateCustomAmounts(
        input.amount,
        installmentAmounts,
      );
    }
    final groupId = _groupIdGenerator();
    final planId = installmentAmounts.length > 1
        ? '$groupId-installments'
        : null;
    final originalDate = _formatDate(input.paymentDate);
    final transactions = [
      for (final (index, amount) in installmentAmounts.indexed)
        Transaction(
          id: _idGenerator(index),
          accountId: input.accountId,
          creditCardId: input.creditCardId,
          amount: input.creditCardId != null
              ? amount
              : isCollection
              ? amount
              : -amount,
          transactionType: input.creditCardId != null
              ? TransactionType.expense
              : TransactionType.transfer,
          categoryId: null,
          merchant: installmentAmounts.length > 1
              ? '$description ${index + 1}/${installmentAmounts.length} '
                    '$originalDate'
              : description,
          note: null,
          transactionDate: InstallmentCalculator.installmentDate(
            input.paymentDate,
            index,
          ),
          source: TransactionSource.manual,
          isDeleted: false,
          installmentPlanId: planId,
          installmentNumber: planId == null ? null : index + 1,
          installmentCount: planId == null ? null : installmentAmounts.length,
          installmentTotalAmount: planId == null ? null : input.amount,
          paymentGroupId: groupId,
          customerId: customer.id,
          customerBalanceDelta: isCollection ? -amount : amount,
        ),
    ];
    if (transactions.length == 1) {
      await _transactionRepository.create(transactions.single);
    } else {
      await _transactionRepository.createMany(transactions);
    }
    return transactions.first;
  }

  void _validateShape(CustomerPaymentInput input) {
    if (!input.amount.isFinite || input.amount <= 0) {
      throw ArgumentError.value(input.amount, 'amount');
    }
    if (input.paymentDate.isAfter(_clock())) {
      throw ArgumentError.value(input.paymentDate, 'paymentDate');
    }
    if ((input.accountId == null) == (input.creditCardId == null)) {
      throw ArgumentError('Exactly one payment source is required.');
    }
    if (input.direction == CustomerPaymentDirection.collect &&
        input.creditCardId != null) {
      throw ArgumentError('Collections must be received into an account.');
    }
  }

  Future<void> _validatePaymentSource(
    CustomerPaymentInput input,
    String currencyCode,
  ) async {
    if (input.accountId case final accountId?) {
      final accounts = await _accountRepository.getAccounts();
      final account = accounts
          .where((item) => item.id == accountId)
          .firstOrNull;
      if (account == null || account.isArchived) {
        throw ArgumentError.value(accountId, 'accountId');
      }
      if (account.currencyCode != currencyCode) {
        throw ArgumentError('Customer and account currencies must match.');
      }
      if (input.direction == CustomerPaymentDirection.pay) {
        final balance = await _calculateAccountBalance.execute(accountId);
        if (balance.currentBalance < input.amount) {
          throw const CustomerOperationException(
            'Seçilen kasa veya banka hesabında yeterli bakiye yok.',
          );
        }
      }
      return;
    }
    final cardId = input.creditCardId!;
    final cards = await _creditCardRepository.getCreditCards();
    final card = cards.where((item) => item.id == cardId).firstOrNull;
    if (card == null || card.isArchived) {
      throw ArgumentError.value(cardId, 'creditCardId');
    }
    if (card.currencyCode != currencyCode) {
      throw ArgumentError('Customer and card currencies must match.');
    }
    final balance = await _calculateCreditCardBalance.execute(cardId);
    if (balance.availableLimit < input.amount) {
      throw const CustomerOperationException(
        'Seçilen kredi kartında yeterli kullanılabilir limit yok.',
      );
    }
  }

  static String _generateId(int index) =>
      'customer-payment-${DateTime.now().microsecondsSinceEpoch}-$index';
  static String _generateGroupId() =>
      'customer-payment-group-${DateTime.now().microsecondsSinceEpoch}';

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.'
      '${(value.year % 100).toString().padLeft(2, '0')}';
}
