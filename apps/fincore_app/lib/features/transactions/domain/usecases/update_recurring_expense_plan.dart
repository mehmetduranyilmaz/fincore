import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_recurring_expense_plan_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/recurring_expense_plan_repository.dart';
import 'package:fincore_app/features/transactions/domain/services/transaction_category_validator.dart';
import 'package:fincore_app/features/transactions/domain/usecases/manual_transaction_validator.dart';

final class UpdateRecurringExpensePlanUseCase {
  const UpdateRecurringExpensePlanUseCase(
    this._repository,
    this._accountRepository,
    this._creditCardRepository,
    this._customerRepository, {
    this.categoryValidator,
  });

  final RecurringExpensePlanRepository _repository;
  final AccountRepository _accountRepository;
  final CreditCardRepository _creditCardRepository;
  final CustomerRepository _customerRepository;
  final TransactionCategoryValidator? categoryValidator;

  Future<RecurringExpensePlan> execute(
    String planId,
    CreateRecurringExpensePlanInput input,
  ) async {
    if (planId.trim().isEmpty) throw ArgumentError.value(planId, 'planId');
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
    if (input.firstDueDate.isBefore(DateTime(2000))) {
      throw ArgumentError.value(input.firstDueDate, 'firstDueDate');
    }
    if (input.occurrenceCount < RecurringExpensePlan.minimumOccurrenceCount ||
        input.occurrenceCount > RecurringExpensePlan.maximumOccurrenceCount) {
      throw ArgumentError.value(input.occurrenceCount, 'occurrenceCount');
    }

    final plans = await _repository.getPlans();
    if (!plans.any((plan) => plan.id == planId)) {
      throw StateError('Recurring expense plan not found.');
    }
    if (input.categoryId != null && categoryValidator != null) {
      await categoryValidator!.validate(
        categoryId: input.categoryId!,
        transactionType: TransactionType.expense,
      );
    }

    final updated = RecurringExpensePlan(
      id: planId,
      accountId: input.accountId,
      creditCardId: input.creditCardId,
      customerId: input.customerId,
      amount: input.amount,
      description: input.description.trim(),
      categoryId: input.categoryId,
      currencyCode: await _resolveCurrency(input),
      firstDueDate: input.firstDueDate,
      occurrenceCount: input.occurrenceCount,
    );
    await _repository.update(updated);
    return updated;
  }

  Future<String> _resolveCurrency(CreateRecurringExpensePlanInput input) async {
    if (input.accountId case final accountId?) {
      final accounts = await _accountRepository.getAccounts();
      final matches = accounts.where(
        (account) => account.id == accountId && !account.isArchived,
      );
      if (matches.isNotEmpty) return matches.first.currencyCode;
      throw ArgumentError.value(accountId, 'accountId');
    }
    if (input.creditCardId case final creditCardId?) {
      final cards = await _creditCardRepository.getCreditCards();
      final matches = cards.where(
        (card) => card.id == creditCardId && !card.isArchived,
      );
      if (matches.isNotEmpty) return matches.first.currencyCode;
      throw ArgumentError.value(creditCardId, 'creditCardId');
    }
    final customer = await _customerRepository.getById(input.customerId!);
    if (customer == null || customer.isArchived) {
      throw ArgumentError.value(input.customerId, 'customerId');
    }
    return customer.currencyCode;
  }
}
