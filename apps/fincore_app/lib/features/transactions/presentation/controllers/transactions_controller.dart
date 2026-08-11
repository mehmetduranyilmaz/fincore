import 'dart:async';

import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_filter.dart';
import 'package:fincore_app/features/transactions/domain/usecases/get_transactions.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transaction_filter_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransactionsStatus { initial, loading, loaded, failure }

final class TransactionsState {
  const TransactionsState._({
    required this.status,
    required this.revision,
    this.transactions = const [],
    this.errorMessage,
  });

  const TransactionsState.initial()
    : this._(status: TransactionsStatus.initial, revision: 0);

  const TransactionsState.loading(int revision)
    : this._(status: TransactionsStatus.loading, revision: revision);

  TransactionsState.loaded(List<Transaction> transactions, int revision)
    : this._(
        status: TransactionsStatus.loaded,
        revision: revision,
        transactions: List.unmodifiable(transactions),
      );

  const TransactionsState.failure(String message, int revision)
    : this._(
        status: TransactionsStatus.failure,
        revision: revision,
        errorMessage: message,
      );

  final TransactionsStatus status;
  final int revision;
  final List<Transaction> transactions;
  final String? errorMessage;
}

final transactionsControllerProvider =
    NotifierProvider<TransactionsController, TransactionsState>(
      TransactionsController.new,
    );

final class TransactionsController extends Notifier<TransactionsState> {
  late GetTransactions _getTransactions;
  int _requestId = 0;

  @override
  TransactionsState build() {
    _getTransactions = ref.watch(getTransactionsProvider);
    ref.listen<TransactionFilter>(
      transactionFilterControllerProvider,
      (previous, next) => unawaited(load()),
    );
    return const TransactionsState.initial();
  }

  Future<void> load() async {
    final requestId = ++_requestId;
    final revision = state.revision;
    state = TransactionsState.loading(revision);

    try {
      final filter = ref.read(transactionFilterControllerProvider);
      final transactions = await _getTransactions.execute(filter);
      if (requestId == _requestId) {
        state = TransactionsState.loaded(transactions, revision + 1);
      }
    } on Object catch (error) {
      if (requestId == _requestId) {
        state = TransactionsState.failure(ErrorMapper.map(error), revision);
      }
    }
  }
}
