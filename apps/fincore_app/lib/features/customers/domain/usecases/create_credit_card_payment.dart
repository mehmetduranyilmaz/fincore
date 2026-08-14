import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/domain/usecases/calculate_account_balance.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/calculate_credit_card_balance.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_statement_payment_status.dart';
import 'package:fincore_app/features/customers/domain/entities/credit_card_payment_input.dart';
import 'package:fincore_app/features/customers/domain/errors/customer_operation_exception.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

typedef PaymentClock = DateTime Function();
typedef PaymentIdGenerator = String Function(int index);
typedef PaymentGroupIdGenerator = String Function();

final class CreateCreditCardPaymentUseCase {
  CreateCreditCardPaymentUseCase(
    this._transactionRepository,
    this._accountRepository,
    this._creditCardRepository,
    this._creditCardStatementRepository,
    this._calculateAccountBalance,
    this._calculateCreditCardBalance, {
    PaymentClock? clock,
    PaymentIdGenerator? idGenerator,
    PaymentGroupIdGenerator? groupIdGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _generateId,
       _groupIdGenerator = groupIdGenerator ?? _generateGroupId;

  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final CreditCardRepository _creditCardRepository;
  final CreditCardStatementRepository _creditCardStatementRepository;
  final CalculateAccountBalanceUseCase _calculateAccountBalance;
  final CalculateCreditCardBalanceUseCase _calculateCreditCardBalance;
  final PaymentClock _clock;
  final PaymentIdGenerator _idGenerator;
  final PaymentGroupIdGenerator _groupIdGenerator;

  Future<List<Transaction>> execute(CreditCardPaymentInput input) async {
    _validateShape(input);
    final accounts = await _accountRepository.getAccounts();
    final account = accounts
        .where((item) => item.id == input.fromAccountId)
        .firstOrNull;
    if (account == null || account.isArchived) {
      throw ArgumentError.value(input.fromAccountId, 'fromAccountId');
    }
    final cards = await _creditCardRepository.getCreditCards();
    final card = cards
        .where((item) => item.id == input.creditCardId)
        .firstOrNull;
    if (card == null || card.isArchived) {
      throw ArgumentError.value(input.creditCardId, 'creditCardId');
    }
    if (account.currencyCode != card.currencyCode) {
      throw ArgumentError('Account and card currencies must match.');
    }
    final accountBalance = await _calculateAccountBalance.execute(
      input.fromAccountId,
    );
    if (accountBalance.currentBalance < input.amount) {
      throw const CustomerOperationException(
        'Seçilen kasa veya banka hesabında yeterli bakiye yok.',
      );
    }
    final cardBalance = await _calculateCreditCardBalance.execute(card.id);
    if (input.amount > cardBalance.currentDebt) {
      throw const CustomerOperationException(
        'Ödeme tutarı güncel kredi kartı borcunu aşamaz.',
      );
    }
    if (input.statementId case final statementId?) {
      final status = await GetCreditCardStatementPaymentStatusUseCase(
        _creditCardStatementRepository,
        _transactionRepository,
      ).execute(creditCardId: card.id, statementId: statementId);
      if (status.isPaid) {
        throw const CustomerOperationException('Bu ekstre zaten ödendi.');
      }
      if (input.amount - status.remainingAmount > 0.005) {
        throw const CustomerOperationException(
          'Ödeme tutarı ekstrenin kalan borcunu aşamaz.',
        );
      }
    }

    final groupId = _groupIdGenerator();
    final description = input.description.trim().isEmpty
        ? 'Kredi Kartı Ödemesi - ${card.cardName}'
        : input.description.trim();
    final transactions = List<Transaction>.unmodifiable([
      Transaction(
        id: _idGenerator(0),
        accountId: input.fromAccountId,
        creditCardId: null,
        amount: -input.amount,
        transactionType: TransactionType.transfer,
        categoryId: null,
        merchant: description,
        note: null,
        transactionDate: input.paymentDate,
        source: TransactionSource.manual,
        isDeleted: false,
        paymentGroupId: groupId,
        creditCardStatementId: input.statementId,
      ),
      Transaction(
        id: _idGenerator(1),
        accountId: null,
        creditCardId: card.id,
        amount: input.amount,
        transactionType: TransactionType.income,
        categoryId: null,
        merchant: description,
        note: null,
        transactionDate: input.paymentDate,
        source: TransactionSource.manual,
        isDeleted: false,
        paymentGroupId: groupId,
        creditCardStatementId: input.statementId,
      ),
    ]);
    await _transactionRepository.createMany(transactions);
    return transactions;
  }

  void _validateShape(CreditCardPaymentInput input) {
    if (!input.amount.isFinite || input.amount <= 0) {
      throw ArgumentError.value(input.amount, 'amount');
    }
    if (input.paymentDate.isAfter(_clock())) {
      throw ArgumentError.value(input.paymentDate, 'paymentDate');
    }
    if (input.statementId != null && input.statementId!.trim().isEmpty) {
      throw ArgumentError.value(input.statementId, 'statementId');
    }
  }

  static String _generateId(int index) =>
      'card-payment-${DateTime.now().microsecondsSinceEpoch}-$index';
  static String _generateGroupId() =>
      'card-payment-group-${DateTime.now().microsecondsSinceEpoch}';
}
