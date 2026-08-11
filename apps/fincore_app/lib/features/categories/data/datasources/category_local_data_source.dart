import 'dart:convert';

import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';
import 'package:fincore_app/features/categories/data/datasources/category_mock_data_source.dart';
import 'package:fincore_app/features/categories/data/models/category_dto.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';

final class CategoryLocalDataSource implements CategoryDataSource {
  const CategoryLocalDataSource(this._storage);

  static const String _storageKey = 'categories_v1';
  static const String _defaultsVersionKey = 'categories_defaults_version';
  static const int _defaultsVersion = 1;
  final SecureStorageService _storage;

  @override
  Future<List<Category>> getAll() async => List.unmodifiable(await _readAll());

  @override
  Future<Category?> getById(String categoryId) async {
    for (final category in await _readAll()) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  @override
  Future<void> insert(Category category) async {
    final categories = await _readAll();
    if (categories.any((item) => item.id == category.id)) {
      throw StateError('Category already exists.');
    }
    await _writeAll([...categories, category]);
  }

  @override
  Future<void> replace(Category category) async {
    final categories = await _readAll();
    final index = categories.indexWhere((item) => item.id == category.id);
    if (index < 0) throw StateError('Category not found.');
    if (categories[index].type != category.type) {
      throw StateError('Category type cannot be changed.');
    }
    categories[index] = category;
    await _writeAll(categories);
  }

  @override
  Future<void> remove(String categoryId) async {
    final categories = await _readAll();
    final removed = categories.where((item) => item.id == categoryId).length;
    categories.removeWhere((item) => item.id == categoryId);
    if (removed == 0) throw StateError('Category not found.');
    await _writeAll(categories);
  }

  Future<List<Category>> _readAll() async {
    final value = await _storage.read(key: _storageKey);
    final categories = value == null || value.isEmpty
        ? <Category>[]
        : _decode(value);
    final storedVersion =
        int.tryParse(await _storage.read(key: _defaultsVersionKey) ?? '') ?? 0;
    if (storedVersion < _defaultsVersion) {
      for (final requiredCategory in CategoryMockDataSource.defaultCategories) {
        final exists = categories.any(
          (item) =>
              item.id == requiredCategory.id ||
              TurkishText.normalize(item.name) ==
                  TurkishText.normalize(requiredCategory.name),
        );
        if (!exists) categories.add(requiredCategory);
      }
      await _writeAll(categories);
      await _storage.write(
        key: _defaultsVersionKey,
        value: _defaultsVersion.toString(),
      );
    }
    return categories;
  }

  List<Category> _decode(String value) {
    final json = jsonDecode(value);
    if (json is! List<Object?>) {
      throw const FormatException('Invalid category storage.');
    }
    return [
      for (final item in json)
        CategoryDto.fromJson(item! as Map<String, Object?>).category,
    ];
  }

  Future<void> _writeAll(List<Category> categories) {
    return _storage.write(
      key: _storageKey,
      value: jsonEncode([
        for (final category in categories) CategoryDto(category).toJson(),
      ]),
    );
  }
}
