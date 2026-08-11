import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/categories/data/datasources/category_local_data_source.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('keeps user categories while merging required defaults', () async {
    final dataSource = CategoryLocalDataSource(
      SecureStorageService(const FlutterSecureStorage()),
    );
    const custom = Category(
      id: 'category-custom',
      name: 'Kullanıcı Kategorisi',
      icon: 'home',
      color: 0xFF123456,
      type: CategoryType.expense,
    );

    await dataSource.insert(custom);
    final categories = await dataSource.getAll();

    expect(categories, contains(custom));
    expect(categories.map((item) => item.name), contains('Elektrik'));
    expect(categories.map((item) => item.name), contains('Araç Bakım'));
  });

  test(
    'does not restore a default category after the user deletes it',
    () async {
      final dataSource = CategoryLocalDataSource(
        SecureStorageService(const FlutterSecureStorage()),
      );

      await dataSource.getAll();
      await dataSource.remove('category-electricity');

      expect(
        (await dataSource.getAll()).map((item) => item.id),
        isNot(contains('category-electricity')),
      );
    },
  );
}
