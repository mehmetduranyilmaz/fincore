import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/parse_receipt_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts editable receipt suggestions', () async {
    const receipt = '''
MİGROS TİCARET A.Ş.
TARİH: 10.08.2026 SAAT: 14:30
KART NO: **** **** **** 1234
3 TAKSİT
KDV 18,00
GENEL TOPLAM 1.234,56 TL
''';

    final result = await ParseReceiptTextUseCase(
      const _CategoryRepository(),
    ).execute(receipt);

    expect(result.totalAmount, 1234.56);
    expect(result.description, 'MİGROS TİCARET A.Ş.');
    expect(result.transactionDate, DateTime(2026, 8, 10));
    expect(result.lastFourDigits, '1234');
    expect(result.installmentCount, 3);
    expect(result.suggestedCategoryId, 'category-grocery');
  });
}

final class _CategoryRepository implements CategoryRepository {
  const _CategoryRepository();

  static const categories = [
    Category(
      id: 'category-grocery',
      name: 'Groceries',
      icon: 'shopping_cart',
      color: 0,
      type: CategoryType.expense,
    ),
  ];

  @override
  Future<void> create(Category category) async {}

  @override
  Future<void> delete(String categoryId) async {}

  @override
  Future<List<Category>> getAll() async => categories;

  @override
  Future<Category?> getById(String categoryId) async {
    return categoryId == categories.single.id ? categories.single : null;
  }

  @override
  Future<void> update(Category category) async {}
}
