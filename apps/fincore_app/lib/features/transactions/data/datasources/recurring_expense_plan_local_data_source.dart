import 'dart:convert';

import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/transactions/data/models/recurring_expense_plan_dto.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';

abstract interface class RecurringExpensePlanDataSource {
  Future<List<RecurringExpensePlan>> getPlans();

  Future<void> insert(RecurringExpensePlan plan);

  Future<void> replace(RecurringExpensePlan plan);

  Future<void> remove(String planId);
}

final class RecurringExpensePlanLocalDataSource
    implements RecurringExpensePlanDataSource {
  const RecurringExpensePlanLocalDataSource(this._storage);

  static const String storageKey = 'recurring_expense_plans_v1';

  final SecureStorageService _storage;

  @override
  Future<List<RecurringExpensePlan>> getPlans() async =>
      List.unmodifiable(await _readAll());

  @override
  Future<void> insert(RecurringExpensePlan plan) async {
    final plans = await _readAll();
    if (plans.any((item) => item.id == plan.id)) {
      throw StateError('Recurring expense plan already exists.');
    }
    await _writeAll([plan, ...plans]);
  }

  @override
  Future<void> replace(RecurringExpensePlan plan) async {
    final plans = await _readAll();
    final index = plans.indexWhere((item) => item.id == plan.id);
    if (index < 0) throw StateError('Recurring expense plan not found.');
    plans[index] = plan;
    await _writeAll(plans);
  }

  @override
  Future<void> remove(String planId) async {
    final plans = await _readAll();
    final removed = plans.where((item) => item.id == planId).length;
    if (removed == 0) throw StateError('Recurring expense plan not found.');
    plans.removeWhere((item) => item.id == planId);
    await _writeAll(plans);
  }

  Future<List<RecurringExpensePlan>> _readAll() async {
    final value = await _storage.read(key: storageKey);
    if (value == null || value.isEmpty) return [];
    final decoded = jsonDecode(value);
    if (decoded is! List<Object?>) {
      throw const FormatException('Invalid recurring expense plan storage.');
    }
    return [
      for (final item in decoded)
        RecurringExpensePlanDto.fromJson(
          (item! as Map).cast<String, Object?>(),
        ).plan,
    ];
  }

  Future<void> _writeAll(List<RecurringExpensePlan> plans) {
    return _storage.write(
      key: storageKey,
      value: jsonEncode([
        for (final plan in plans) RecurringExpensePlanDto(plan).toJson(),
      ]),
    );
  }
}
