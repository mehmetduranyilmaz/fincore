import 'dart:convert';

import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/credit_cards/data/models/credit_card_statement_dto.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';

abstract interface class CreditCardStatementDataSource {
  Future<List<CreditCardStatement>> getByCreditCardId(String creditCardId);

  Future<void> insert(CreditCardStatement statement);
}

final class CreditCardStatementLocalDataSource
    implements CreditCardStatementDataSource {
  const CreditCardStatementLocalDataSource(this._storage);

  static const String _storageKey = 'credit_card_statements_v1';
  final SecureStorageService _storage;

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(
    String creditCardId,
  ) async {
    return List.unmodifiable(
      (await _readAll()).where(
        (statement) => statement.creditCardId == creditCardId,
      ),
    );
  }

  @override
  Future<void> insert(CreditCardStatement statement) async {
    final statements = await _readAll();
    if (statements.any((item) => item.id == statement.id)) {
      throw StateError('Credit card statement already exists.');
    }
    final assignedTransactionIds = statements
        .expand((item) => item.lines)
        .map((line) => line.transactionId)
        .toSet();
    if (statement.lines.any(
      (line) => assignedTransactionIds.contains(line.transactionId),
    )) {
      throw StateError('A transaction is already assigned to a statement.');
    }
    await _writeAll([statement, ...statements]);
  }

  Future<List<CreditCardStatement>> _readAll() async {
    final value = await _storage.read(key: _storageKey);
    if (value == null || value.isEmpty) return [];
    final json = jsonDecode(value);
    if (json is! List<Object?>) {
      throw const FormatException('Invalid credit card statement storage.');
    }
    return [
      for (final item in json)
        CreditCardStatementDto.fromJson(
          item! as Map<String, Object?>,
        ).statement,
    ];
  }

  Future<void> _writeAll(List<CreditCardStatement> statements) {
    return _storage.write(
      key: _storageKey,
      value: jsonEncode([
        for (final statement in statements)
          CreditCardStatementDto(statement).toJson(),
      ]),
    );
  }
}
