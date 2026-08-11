import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';

final class TransactionFilter {
  factory TransactionFilter({
    Set<TransactionType> transactionTypes = const {},
    String? accountId,
    String? creditCardId,
    DateTime? startDate,
    DateTime? endDate,
    String searchText = '',
  }) {
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      throw ArgumentError.value(endDate, 'endDate');
    }

    return TransactionFilter._(
      transactionTypes: Set.unmodifiable(transactionTypes),
      accountId: accountId,
      creditCardId: creditCardId,
      startDate: startDate,
      endDate: endDate,
      searchText: searchText,
    );
  }

  const TransactionFilter._({
    required this.transactionTypes,
    required this.accountId,
    required this.creditCardId,
    required this.startDate,
    required this.endDate,
    required this.searchText,
  });

  final Set<TransactionType> transactionTypes;
  final String? accountId;
  final String? creditCardId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchText;

  bool get hasFilters {
    return transactionTypes.isNotEmpty ||
        accountId != null ||
        creditCardId != null ||
        startDate != null ||
        endDate != null ||
        searchText.trim().isNotEmpty;
  }

  TransactionFilter copyWith({
    Set<TransactionType>? transactionTypes,
    String? accountId,
    bool clearAccountId = false,
    String? creditCardId,
    bool clearCreditCardId = false,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDateRange = false,
    String? searchText,
  }) {
    return TransactionFilter(
      transactionTypes: transactionTypes ?? this.transactionTypes,
      accountId: clearAccountId ? null : accountId ?? this.accountId,
      creditCardId: clearCreditCardId
          ? null
          : creditCardId ?? this.creditCardId,
      startDate: clearDateRange ? null : startDate ?? this.startDate,
      endDate: clearDateRange ? null : endDate ?? this.endDate,
      searchText: searchText ?? this.searchText,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TransactionFilter &&
            _setsEqual(transactionTypes, other.transactionTypes) &&
            accountId == other.accountId &&
            creditCardId == other.creditCardId &&
            startDate == other.startDate &&
            endDate == other.endDate &&
            searchText == other.searchText;
  }

  @override
  int get hashCode {
    final sortedTypes = transactionTypes.toList()
      ..sort((first, second) => first.index.compareTo(second.index));
    return Object.hash(
      Object.hashAll(sortedTypes),
      accountId,
      creditCardId,
      startDate,
      endDate,
      searchText,
    );
  }
}

bool _setsEqual<T>(Set<T> first, Set<T> second) {
  return first.length == second.length && first.containsAll(second);
}
