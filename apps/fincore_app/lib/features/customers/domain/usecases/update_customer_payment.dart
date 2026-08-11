import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/domain/usecases/calculate_account_balance.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/calculate_credit_card_balance.dart';
import 'package:fincore_app/features/customers/domain/entities/update_customer_payment_input.dart';
import 'package:fincore_app/features/customers/domain/errors/customer_operation_exception.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class UpdateCustomerPaymentUseCase {
  const UpdateCustomerPaymentUseCase(
    this._transactionRepository,
    this._customerRepository,
    this._accountRepository,
    this._creditCardRepository,
    this._calculateAccountBalance,
    this._calculateCreditCardBalance,
  );

  final TransactionRepository _transactionRepository;
  final CustomerRepository _customerRepository;
  final AccountRepository _accountRepository;
  final CreditCardRepository _creditCardRepository;
  final CalculateAccountBalanceUseCase _calculateAccountBalance;
  final CalculateCreditCardBalanceUseCase _calculateCreditCardBalance;

  Future<Transaction> execute(UpdateCustomerPaymentInput input) async {
    if (input.transactionId.trim().isEmpty ||
        !input.amount.isFinite ||
        input.amount <= 0 ||
        input.paymentDate.isAfter(DateTime.now()) ||
        (input.accountId == null) == (input.creditCardId == null)) {
      throw const CustomerOperationException('Girilen bilgileri kontrol edin.');
    }
    final current = await _transactionRepository.getById(input.transactionId);
    if (current == null || current.isDeleted || !current.isCustomerPayment) {
      throw const CustomerOperationException('Müşteri hareketi bulunamadı.');
    }
    final customer = await _customerRepository.getById(current.customerId!);
    if (customer == null || customer.isArchived) {
      throw const CustomerOperationException('Müşteri bulunamadı.');
    }
    final isCollection = current.customerBalanceDelta! < 0;
    if (isCollection && input.creditCardId != null) {
      throw const CustomerOperationException(
        'Tahsilat yalnızca kasa veya banka hesabına alınabilir.',
      );
    }
    await _validateSource(input, current, customer.currencyCode, isCollection);
    final description = input.description.trim().isEmpty
        ? '${isCollection ? 'Tahsilat' : 'Ödeme'} - ${customer.name}'
        : input.description.trim();
    final updated = Transaction(
      id: current.id,
      accountId: input.accountId,
      creditCardId: input.creditCardId,
      amount: input.creditCardId != null
          ? input.amount
          : isCollection
          ? input.amount
          : -input.amount,
      transactionType: input.creditCardId != null
          ? TransactionType.expense
          : TransactionType.transfer,
      categoryId: null,
      merchant: description,
      note: current.note,
      transactionDate: input.paymentDate,
      source: current.source,
      isDeleted: false,
      paymentGroupId: current.paymentGroupId,
      customerId: current.customerId,
      customerBalanceDelta: isCollection ? -input.amount : input.amount,
    );
    await _transactionRepository.update(updated);
    return updated;
  }

  Future<void> _validateSource(
    UpdateCustomerPaymentInput input,
    Transaction current,
    String currencyCode,
    bool isCollection,
  ) async {
    if (input.accountId case final accountId?) {
      final accounts = await _accountRepository.getAccounts();
      final account = accounts
          .where((item) => item.id == accountId)
          .firstOrNull;
      if (account == null ||
          account.isArchived ||
          account.currencyCode != currencyCode) {
        throw const CustomerOperationException('Geçerli bir hesap seçin.');
      }
      if (!isCollection) {
        final balance = await _calculateAccountBalance.execute(accountId);
        final availableBeforeCurrent =
            balance.currentBalance +
            (current.accountId == accountId ? current.amount.abs() : 0);
        if (availableBeforeCurrent < input.amount) {
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
    if (card == null || card.isArchived || card.currencyCode != currencyCode) {
      throw const CustomerOperationException('Geçerli bir kredi kartı seçin.');
    }
    final balance = await _calculateCreditCardBalance.execute(cardId);
    final availableBeforeCurrent =
        balance.availableLimit +
        (current.creditCardId == cardId ? current.amount.abs() : 0);
    if (availableBeforeCurrent < input.amount) {
      throw const CustomerOperationException(
        'Seçilen kredi kartında yeterli kullanılabilir limit yok.',
      );
    }
  }
}
