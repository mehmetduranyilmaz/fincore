import 'package:fincore_app/features/transactions/domain/entities/create_manual_income_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/services/transaction_category_validator.dart';
import 'package:fincore_app/features/transactions/domain/usecases/manual_transaction_validator.dart';

typedef IncomeClock = DateTime Function();
typedef IncomeIdGenerator = String Function();

final class CreateManualIncomeUseCase {
  CreateManualIncomeUseCase(
    this._repository, {
    this.categoryValidator,
    IncomeClock? clock,
    IncomeIdGenerator? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _generateId;

  final TransactionRepository _repository;
  final TransactionCategoryValidator? categoryValidator;
  final IncomeClock _clock;
  final IncomeIdGenerator _idGenerator;

  Future<Transaction> execute(CreateManualIncomeInput input) async {
    _validate(input);
    await _validateCategory(input.categoryId);

    final transaction = Transaction(
      id: _idGenerator(),
      accountId: input.accountId,
      creditCardId: null,
      amount: input.amount,
      transactionType: TransactionType.income,
      categoryId: input.categoryId,
      merchant: input.description.trim(),
      note: null,
      transactionDate: input.transactionDate,
      source: TransactionSource.manual,
      isDeleted: false,
    );

    await _repository.create(transaction);

    return transaction;
  }

  Future<void> _validateCategory(String? categoryId) async {
    if (categoryId == null || categoryValidator == null) {
      return;
    }
    await categoryValidator!.validate(
      categoryId: categoryId,
      transactionType: TransactionType.income,
    );
  }

  void _validate(CreateManualIncomeInput input) {
    ManualTransactionValidator.validateAmount(input.amount);
    ManualTransactionValidator.validateRequiredId(input.accountId, 'accountId');
    ManualTransactionValidator.validateDescription(input.description);
    ManualTransactionValidator.validateDate(input.transactionDate, _clock());
  }

  static String _generateId() {
    return 'manual-income-${DateTime.now().microsecondsSinceEpoch}';
  }
}
