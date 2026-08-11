import 'package:fincore_app/features/transactions/domain/entities/transaction_filter.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionFilterControllerProvider =
    NotifierProvider<TransactionFilterController, TransactionFilter>(
      TransactionFilterController.new,
    );

final class TransactionFilterController extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter();

  void setSearchText(String searchText) {
    state = state.copyWith(searchText: searchText);
  }

  void toggleTransactionType(TransactionType type) {
    final transactionTypes = {...state.transactionTypes};
    if (!transactionTypes.add(type)) {
      transactionTypes.remove(type);
    }
    state = state.copyWith(transactionTypes: transactionTypes);
  }

  void setAccountId(String? accountId) {
    state = state.copyWith(
      accountId: accountId,
      clearAccountId: accountId == null,
      clearCreditCardId: accountId != null,
    );
  }

  void setCreditCardId(String? creditCardId) {
    state = state.copyWith(
      creditCardId: creditCardId,
      clearCreditCardId: creditCardId == null,
      clearAccountId: creditCardId != null,
    );
  }

  void setDateRange({required DateTime startDate, required DateTime endDate}) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  void clearDateRange() {
    state = state.copyWith(clearDateRange: true);
  }

  void reset() {
    state = TransactionFilter();
  }
}
