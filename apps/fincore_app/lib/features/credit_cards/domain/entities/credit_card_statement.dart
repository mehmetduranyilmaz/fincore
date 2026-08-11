final class CreditCardStatementLine {
  const CreditCardStatementLine({
    required this.transactionId,
    required this.description,
    required this.transactionDate,
    required this.amount,
    this.installmentNumber,
    this.installmentCount,
  });

  final String transactionId;
  final String description;
  final DateTime transactionDate;

  /// Positive values are charges; negative values are refunds.
  final double amount;
  final int? installmentNumber;
  final int? installmentCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CreditCardStatementLine &&
            transactionId == other.transactionId &&
            description == other.description &&
            transactionDate == other.transactionDate &&
            amount == other.amount &&
            installmentNumber == other.installmentNumber &&
            installmentCount == other.installmentCount;
  }

  @override
  int get hashCode => Object.hash(
    transactionId,
    description,
    transactionDate,
    amount,
    installmentNumber,
    installmentCount,
  );
}

final class CreditCardStatement {
  CreditCardStatement({
    required this.id,
    required this.creditCardId,
    required this.statementDate,
    required this.dueDate,
    required List<CreditCardStatementLine> lines,
    required this.createdAt,
  }) : lines = List.unmodifiable(lines) {
    if (id.trim().isEmpty || creditCardId.trim().isEmpty || lines.isEmpty) {
      throw ArgumentError('Invalid credit card statement.');
    }
    if (!dueDate.isAfter(statementDate)) {
      throw ArgumentError('Due date must be after statement date.');
    }
    final transactionIds = lines.map((line) => line.transactionId).toSet();
    if (transactionIds.length != lines.length ||
        lines.any(
          (line) =>
              line.transactionId.trim().isEmpty ||
              line.description.trim().isEmpty ||
              !line.amount.isFinite ||
              line.amount == 0,
        )) {
      throw ArgumentError('Invalid credit card statement lines.');
    }
  }

  final String id;
  final String creditCardId;
  final DateTime statementDate;
  final DateTime dueDate;
  final List<CreditCardStatementLine> lines;
  final DateTime createdAt;

  double get totalAmount => lines.fold(0, (total, line) => total + line.amount);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CreditCardStatement &&
            id == other.id &&
            creditCardId == other.creditCardId &&
            statementDate == other.statementDate &&
            dueDate == other.dueDate &&
            _listEquals(lines, other.lines) &&
            createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    creditCardId,
    statementDate,
    dueDate,
    Object.hashAll(lines),
    createdAt,
  );

  static bool _listEquals(
    List<CreditCardStatementLine> left,
    List<CreditCardStatementLine> right,
  ) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
