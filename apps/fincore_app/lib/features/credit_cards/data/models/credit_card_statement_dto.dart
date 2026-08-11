import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';

final class CreditCardStatementDto {
  const CreditCardStatementDto(this.statement);

  factory CreditCardStatementDto.fromJson(Map<String, Object?> json) {
    final rawLines = json['lines'];
    if (rawLines is! List<Object?>) {
      throw const FormatException('Invalid credit card statement lines.');
    }
    return CreditCardStatementDto(
      CreditCardStatement(
        id: json['id']! as String,
        creditCardId: json['creditCardId']! as String,
        statementDate: DateTime.parse(json['statementDate']! as String),
        dueDate: DateTime.parse(json['dueDate']! as String),
        createdAt: DateTime.parse(json['createdAt']! as String),
        lines: [
          for (final rawLine in rawLines)
            _lineFromJson(rawLine! as Map<String, Object?>),
        ],
      ),
    );
  }

  final CreditCardStatement statement;

  Map<String, Object?> toJson() => {
    'id': statement.id,
    'creditCardId': statement.creditCardId,
    'statementDate': statement.statementDate.toIso8601String(),
    'dueDate': statement.dueDate.toIso8601String(),
    'createdAt': statement.createdAt.toIso8601String(),
    'lines': [for (final line in statement.lines) _lineToJson(line)],
  };

  static CreditCardStatementLine _lineFromJson(Map<String, Object?> json) {
    return CreditCardStatementLine(
      transactionId: json['transactionId']! as String,
      description: json['description']! as String,
      transactionDate: DateTime.parse(json['transactionDate']! as String),
      amount: (json['amount']! as num).toDouble(),
      installmentNumber: json['installmentNumber'] as int?,
      installmentCount: json['installmentCount'] as int?,
    );
  }

  static Map<String, Object?> _lineToJson(CreditCardStatementLine line) => {
    'transactionId': line.transactionId,
    'description': line.description,
    'transactionDate': line.transactionDate.toIso8601String(),
    'amount': line.amount,
    'installmentNumber': line.installmentNumber,
    'installmentCount': line.installmentCount,
  };
}
