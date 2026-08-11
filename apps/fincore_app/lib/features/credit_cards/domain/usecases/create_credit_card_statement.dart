import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/errors/credit_card_operation_exception.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_command_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_statement_candidates.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class CreateCreditCardStatementInput {
  const CreateCreditCardStatementInput({
    required this.creditCardId,
    required this.statementDate,
    required this.dueDate,
    required this.transactionIds,
  });

  final String creditCardId;
  final DateTime statementDate;
  final DateTime dueDate;
  final Set<String> transactionIds;
}

typedef CreditCardStatementClock = DateTime Function();
typedef CreditCardStatementIdGenerator = String Function();

final class CreateCreditCardStatementUseCase {
  CreateCreditCardStatementUseCase(
    this._statementRepository,
    this._creditCardRepository,
    this._transactionRepository, {
    CreditCardStatementClock? clock,
    CreditCardStatementIdGenerator? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator =
           idGenerator ??
           (() => 'statement-${DateTime.now().microsecondsSinceEpoch}');

  final CreditCardStatementRepository _statementRepository;
  final CreditCardCommandRepository _creditCardRepository;
  final TransactionRepository _transactionRepository;
  final CreditCardStatementClock _clock;
  final CreditCardStatementIdGenerator _idGenerator;

  Future<CreditCardStatement> execute(
    CreateCreditCardStatementInput input,
  ) async {
    final statementDate = _dateOnly(input.statementDate);
    final dueDate = _dateOnly(input.dueDate);
    final today = _dateOnly(_clock());
    if (input.creditCardId.trim().isEmpty || input.transactionIds.isEmpty) {
      throw const CreditCardOperationException(
        'Ekstre için en az bir hareket seçin.',
      );
    }
    if (statementDate.isAfter(today)) {
      throw const CreditCardOperationException(
        'Ekstre tarihi gelecekte olamaz.',
      );
    }
    if (!dueDate.isAfter(statementDate)) {
      throw const CreditCardOperationException(
        'Son ödeme tarihi ekstre tarihinden sonra olmalıdır.',
      );
    }
    final creditCard = await _creditCardRepository.getById(input.creditCardId);
    if (creditCard == null || creditCard.isArchived) {
      throw const CreditCardOperationException('Kredi kartı bulunamadı.');
    }

    final candidates = await GetCreditCardStatementCandidatesUseCase(
      _statementRepository,
      _transactionRepository,
    ).execute(creditCardId: input.creditCardId, statementDate: statementDate);
    final candidatesById = {for (final item in candidates) item.id: item};
    if (input.transactionIds.any((id) => !candidatesById.containsKey(id))) {
      throw const CreditCardOperationException(
        'Seçilen hareketlerden biri artık ekstreye uygun değil.',
      );
    }
    final selected =
        [for (final id in input.transactionIds) candidatesById[id]!]..sort(
          (left, right) =>
              left.transactionDate.compareTo(right.transactionDate),
        );
    final statement = CreditCardStatement(
      id: _idGenerator(),
      creditCardId: input.creditCardId,
      statementDate: statementDate,
      dueDate: dueDate,
      createdAt: _clock(),
      lines: [for (final transaction in selected) _snapshot(transaction)],
    );
    await _statementRepository.create(statement);
    return statement;
  }

  static CreditCardStatementLine _snapshot(Transaction transaction) {
    final amount = switch (transaction.transactionType) {
      TransactionType.expense => transaction.amount.abs(),
      TransactionType.income => -transaction.amount.abs(),
      TransactionType.transfer => 0.0,
    };
    return CreditCardStatementLine(
      transactionId: transaction.id,
      description: transaction.merchant.trim(),
      transactionDate: _dateOnly(transaction.transactionDate),
      amount: amount,
      installmentNumber: transaction.installmentNumber,
      installmentCount: transaction.installmentCount,
    );
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
