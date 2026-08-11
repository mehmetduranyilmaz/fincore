import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/errors/credit_card_operation_exception.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_command_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_usage_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/create_credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/delete_credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/update_credit_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('credit card CRUD use cases', () {
    test('creates a normalized credit card', () async {
      final repository = _MemoryCreditCardCommandRepository();
      final useCase = CreateCreditCardUseCase(
        repository,
        idGenerator: () => 'credit-card-new',
      );

      final result = await useCase.execute(
        const CreateCreditCardInput(
          bankName: '  Test Bank  ',
          cardName: '  Gold  ',
          lastFourDigits: '1234',
          creditLimit: 50000,
          statementDay: 5,
          dueDay: 15,
          currencyCode: 'try',
        ),
      );

      expect(result.id, 'credit-card-new');
      expect(result.bankName, 'Test Bank');
      expect(result.cardName, 'Gold');
      expect(result.currencyCode, 'TRY');
      expect(repository.items, [result]);
    });

    test('rejects an invalid last four digits value', () async {
      final useCase = CreateCreditCardUseCase(
        _MemoryCreditCardCommandRepository(),
      );

      expect(
        () => useCase.execute(
          const CreateCreditCardInput(
            bankName: 'Test Bank',
            cardName: 'Gold',
            lastFourDigits: '12A4',
            creditLimit: 50000,
            statementDay: 5,
            dueDay: 15,
            currencyCode: 'TRY',
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects the same bank and last four digits combination', () {
      final commandRepository = _MemoryCreditCardCommandRepository();
      final useCase = CreateCreditCardUseCase(
        commandRepository,
        lookupRepository: const _CreditCardLookupRepository([_creditCard]),
      );

      expect(
        () => useCase.execute(
          const CreateCreditCardInput(
            bankName: ' test bank ',
            cardName: 'Another Card',
            lastFourDigits: '1234',
            creditLimit: 50000,
            statementDay: 5,
            dueDay: 15,
            currencyCode: 'TRY',
          ),
        ),
        throwsA(isA<CreditCardOperationException>()),
      );
    });

    test('updates an existing credit card', () async {
      final repository = _MemoryCreditCardCommandRepository([_creditCard]);
      final useCase = UpdateCreditCardUseCase(repository);

      final result = await useCase.execute(
        const UpdateCreditCardInput(
          id: 'credit-card-1',
          bankName: 'Updated Bank',
          cardName: 'Platinum',
          lastFourDigits: '9876',
          creditLimit: 75000,
          statementDay: 8,
          dueDay: 18,
          currencyCode: 'EUR',
          isArchived: true,
        ),
      );

      expect(result.bankName, 'Updated Bank');
      expect(result.isArchived, isTrue);
      expect(await repository.getById(result.id), result);
    });

    test('deletes an existing credit card', () async {
      final repository = _MemoryCreditCardCommandRepository([_creditCard]);

      await DeleteCreditCardUseCase(
        repository,
        const _CreditCardUsageRepository(false),
      ).execute(_creditCard.id);

      expect(repository.items, isEmpty);
    });

    test('does not delete a credit card that has movements', () async {
      final repository = _MemoryCreditCardCommandRepository([_creditCard]);
      final useCase = DeleteCreditCardUseCase(
        repository,
        const _CreditCardUsageRepository(true),
      );

      await expectLater(
        useCase.execute(_creditCard.id),
        throwsA(
          isA<CreditCardOperationException>().having(
            (error) => error.message,
            'message',
            contains('Hareket görmüş'),
          ),
        ),
      );
      expect(repository.items, [_creditCard]);
    });
  });
}

final class _CreditCardUsageRepository implements CreditCardUsageRepository {
  const _CreditCardUsageRepository(this.hasMovements);

  final bool hasMovements;

  @override
  Future<bool> hasUsage(String creditCardId) async => hasMovements;
}

final class _CreditCardLookupRepository implements CreditCardRepository {
  const _CreditCardLookupRepository(this.items);
  final List<CreditCard> items;

  @override
  Future<List<CreditCard>> getCreditCards() async => items;
}

const _creditCard = CreditCard(
  id: 'credit-card-1',
  bankName: 'Test Bank',
  cardName: 'Gold',
  lastFourDigits: '1234',
  creditLimit: 50000,
  statementDay: 5,
  dueDay: 15,
  currencyCode: 'TRY',
  isArchived: false,
);

final class _MemoryCreditCardCommandRepository
    implements CreditCardCommandRepository {
  _MemoryCreditCardCommandRepository([List<CreditCard> seed = const []])
    : items = List.of(seed);

  final List<CreditCard> items;

  @override
  Future<void> create(CreditCard creditCard) async {
    items.add(creditCard);
  }

  @override
  Future<void> delete(String creditCardId) async {
    items.removeWhere((item) => item.id == creditCardId);
  }

  @override
  Future<CreditCard?> getById(String creditCardId) async {
    for (final item in items) {
      if (item.id == creditCardId) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> update(CreditCard creditCard) async {
    final index = items.indexWhere((item) => item.id == creditCard.id);
    items[index] = creditCard;
  }
}
