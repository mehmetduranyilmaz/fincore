import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_recurring_expense_plan_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/recurring_expense_plan_repository.dart';
import 'package:fincore_app/features/transactions/domain/services/transaction_category_validator.dart';
import 'package:fincore_app/features/transactions/domain/usecases/manual_transaction_validator.dart';

typedef RecurringExpensePlanClock = DateTime Function();
typedef RecurringExpensePlanIdGenerator = String Function();

final class CreateRecurringExpensePlanUseCase {
  CreateRecurringExpensePlanUseCase(
    this._repository,
    this._accountRepository,
    this._creditCardRepository,
    this._customerRepository, {
    this.categoryValidator,
    RecurringExpensePlanClock? clock,
    RecurringExpensePlanIdGenerator? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _generateId;

  final RecurringExpensePlanRepository _repository;
  final AccountRepository _accountRepository;
  final CreditCardRepository _creditCardRepository;
  final CustomerRepository _customerRepository;
  final TransactionCategoryValidator? categoryValidator;
  final RecurringExpensePlanClock _clock;
  final RecurringExpensePlanIdGenerator _idGenerator;

  Future<RecurringExpensePlan> execute(
    CreateRecurringExpensePlanInput input,
  ) async {
    _validate(input);
    if (input.categoryId != null && categoryValidator != null) {
      await categoryValidator!.validate(
        categoryId: input.categoryId!,
        transactionType: TransactionType.expense,
      );
    }
    final currencyCode = await _resolveCurrency(input);
    final plan = RecurringExpensePlan(
      id: _idGenerator(),
      accountId: input.accountId,
      creditCardId: input.creditCardId,
      customerId: input.customerId,
      amount: input.amount,
      description: input.description.trim(),
      categoryId: input.categoryId,
      currencyCode: currencyCode,
      firstDueDate: input.firstDueDate,
      occurrenceCount: input.occurrenceCount,
    );
    await _repository.create(plan);
    return plan;
  }

  void _validate(CreateRecurringExpensePlanInput input) {
    ManualTransactionValidator.validateAmount(input.amount);
    ManualTransactionValidator.validateDescription(input.description);
    if ([
          input.accountId,
          input.creditCardId,
          input.customerId,
        ].nonNulls.length !=
        1) {
      throw ArgumentError(
        'Exactly one account, credit card, or open-account customer is required.',
      );
    }
    final now = _clock();
    final currentMonthStart = DateTime(now.year, now.month);
    if (_dateOnly(input.firstDueDate).isBefore(currentMonthStart)) {
      throw ArgumentError.value(input.firstDueDate, 'firstDueDate');
    }
    if (input.occurrenceCount < RecurringExpensePlan.minimumOccurrenceCount ||
        input.occurrenceCount > RecurringExpensePlan.maximumOccurrenceCount) {
      throw ArgumentError.value(input.occurrenceCount, 'occurrenceCount');
    }
  }

  Future<String> _resolveCurrency(CreateRecurringExpensePlanInput input) async {
    if (input.accountId case final accountId?) {
      final accounts = await _accountRepository.getAccounts();
      for (final account in accounts) {
        if (account.id == accountId && !account.isArchived) {
          return account.currencyCode;
        }
      }
      throw ArgumentError.value(accountId, 'accountId');
    }
    if (input.creditCardId case final creditCardId?) {
      final cards = await _creditCardRepository.getCreditCards();
      for (final card in cards) {
        if (card.id == creditCardId && !card.isArchived) {
          return card.currencyCode;
        }
      }
      throw ArgumentError.value(creditCardId, 'creditCardId');
    }
    final customer = await _customerRepository.getById(input.customerId!);
    if (customer == null || customer.isArchived) {
      throw ArgumentError.value(input.customerId, 'customerId');
    }
    return customer.currencyCode;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _generateId() =>
      'recurring-expense-${DateTime.now().microsecondsSinceEpoch}';
}
