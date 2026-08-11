import 'dart:convert';

import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/credit_cards/data/datasources/credit_card_mock_data_source.dart';
import 'package:fincore_app/features/credit_cards/data/models/credit_card_dto.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';

final class CreditCardLocalDataSource
    implements CreditCardDataSource, CreditCardCommandDataSource {
  const CreditCardLocalDataSource(this._storage);

  static const String _storageKey = 'credit_cards_v1';

  final SecureStorageService _storage;

  @override
  Future<List<CreditCard>> getCreditCards() async {
    return List.unmodifiable(await _readAll());
  }

  @override
  Future<CreditCard?> getById(String creditCardId) async {
    final creditCards = await _readAll();
    for (final creditCard in creditCards) {
      if (creditCard.id == creditCardId) {
        return creditCard;
      }
    }
    return null;
  }

  @override
  Future<void> insert(CreditCard creditCard) async {
    final creditCards = await _readAll();
    if (creditCards.any((item) => item.id == creditCard.id)) {
      throw StateError('Credit card already exists.');
    }
    await _writeAll([...creditCards, creditCard]);
  }

  @override
  Future<void> replace(CreditCard creditCard) async {
    final creditCards = await _readAll();
    final index = creditCards.indexWhere((item) => item.id == creditCard.id);
    if (index < 0) {
      throw StateError('Credit card not found.');
    }
    creditCards[index] = creditCard;
    await _writeAll(creditCards);
  }

  @override
  Future<void> remove(String creditCardId) async {
    final creditCards = await _readAll();
    final previousLength = creditCards.length;
    creditCards.removeWhere((item) => item.id == creditCardId);
    if (creditCards.length == previousLength) {
      throw StateError('Credit card not found.');
    }
    await _writeAll(creditCards);
  }

  Future<List<CreditCard>> _readAll() async {
    final value = await _storage.read(key: _storageKey);
    if (value == null || value.isEmpty) {
      return [];
    }

    final json = jsonDecode(value);
    if (json is! List<Object?>) {
      throw const FormatException('Invalid credit card storage.');
    }

    return [
      for (final item in json)
        CreditCardDto.fromJson(item! as Map<String, Object?>).toDomain(),
    ];
  }

  Future<void> _writeAll(List<CreditCard> creditCards) {
    final value = jsonEncode([
      for (final creditCard in creditCards)
        CreditCardDto.fromDomain(creditCard).toJson(),
    ]);
    return _storage.write(key: _storageKey, value: value);
  }
}
