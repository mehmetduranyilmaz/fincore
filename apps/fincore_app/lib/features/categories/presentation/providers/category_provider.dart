import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryProvider = FutureProvider.autoDispose.family<Category?, String>((
  ref,
  categoryId,
) {
  return ref.watch(getCategoryProvider).execute(categoryId);
});
