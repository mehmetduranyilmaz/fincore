import 'dart:convert';

import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/budgets/data/datasources/budget_mock_data_source.dart';
import 'package:fincore_app/features/budgets/data/models/budget_dto.dart';
import 'package:fincore_app/features/budgets/domain/entities/budget.dart';

final class BudgetLocalDataSource implements BudgetDataSource {
  const BudgetLocalDataSource(this._storage);

  static const String _storageKey = 'budgets_v1';
  final SecureStorageService _storage;

  @override
  Future<List<Budget>> getAll() async => List.unmodifiable(
    (await _readAll()).where((budget) => !budget.isDeleted),
  );

  @override
  Future<Budget?> getById(String budgetId) async {
    for (final budget in await _readAll()) {
      if (budget.id == budgetId && !budget.isDeleted) return budget;
    }
    return null;
  }

  @override
  Future<void> insert(Budget budget) async {
    final budgets = await _readAll();
    if (budgets.any((item) => item.id == budget.id)) {
      throw StateError('Budget already exists.');
    }
    await _writeAll([...budgets, budget]);
  }

  @override
  Future<void> replace(Budget budget) async {
    final budgets = await _readAll();
    final index = budgets.indexWhere((item) => item.id == budget.id);
    if (index < 0 || budgets[index].isDeleted) {
      throw StateError('Budget not found.');
    }
    budgets[index] = budget;
    await _writeAll(budgets);
  }

  @override
  Future<void> remove(String budgetId) async {
    final budgets = await _readAll();
    final index = budgets.indexWhere((item) => item.id == budgetId);
    if (index < 0 || budgets[index].isDeleted) {
      throw StateError('Budget not found.');
    }
    budgets[index] = budgets[index].copyWith(
      isDeleted: true,
      updatedAt: DateTime.now(),
    );
    await _writeAll(budgets);
  }

  @override
  Future<bool> exists({
    required String categoryId,
    required int month,
    required int year,
    String? excludingBudgetId,
  }) async {
    return (await _readAll()).any(
      (budget) =>
          !budget.isDeleted &&
          budget.id != excludingBudgetId &&
          budget.categoryId == categoryId &&
          budget.month == month &&
          budget.year == year,
    );
  }

  Future<List<Budget>> _readAll() async {
    final value = await _storage.read(key: _storageKey);
    if (value == null || value.isEmpty) return <Budget>[];
    final json = jsonDecode(value);
    if (json is! List<Object?>) {
      throw const FormatException('Invalid budget storage.');
    }
    return [
      for (final item in json)
        BudgetDto.fromJson(item! as Map<String, Object?>).budget,
    ];
  }

  Future<void> _writeAll(List<Budget> budgets) {
    return _storage.write(
      key: _storageKey,
      value: jsonEncode([
        for (final budget in budgets) BudgetDto(budget).toJson(),
      ]),
    );
  }
}
