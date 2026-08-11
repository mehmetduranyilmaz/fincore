import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final expenseBudgetCategoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
      final categories = await ref.watch(getCategoriesProvider).execute();
      return List.unmodifiable(
        categories.where((category) => category.type == CategoryType.expense),
      );
    });
