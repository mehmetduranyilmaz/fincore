import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/usecases/get_categories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CategoriesStatus { initial, loading, loaded, failure }

final class CategoriesState {
  const CategoriesState._({
    required this.status,
    this.categories = const [],
    this.errorMessage,
  });

  const CategoriesState.initial() : this._(status: CategoriesStatus.initial);

  const CategoriesState.loading() : this._(status: CategoriesStatus.loading);

  CategoriesState.loaded(List<Category> categories)
    : this._(
        status: CategoriesStatus.loaded,
        categories: List.unmodifiable(categories),
      );

  const CategoriesState.failure(String message)
    : this._(status: CategoriesStatus.failure, errorMessage: message);

  final CategoriesStatus status;
  final List<Category> categories;
  final String? errorMessage;
}

final categoriesControllerProvider =
    NotifierProvider<CategoriesController, CategoriesState>(
      CategoriesController.new,
    );

final class CategoriesController extends Notifier<CategoriesState> {
  late GetCategories _getCategories;

  @override
  CategoriesState build() {
    _getCategories = ref.watch(getCategoriesProvider);
    return const CategoriesState.initial();
  }

  Future<void> load() async {
    state = const CategoriesState.loading();
    try {
      state = CategoriesState.loaded(await _getCategories.execute());
    } on Object catch (error) {
      state = CategoriesState.failure(ErrorMapper.map(error));
    }
  }
}
