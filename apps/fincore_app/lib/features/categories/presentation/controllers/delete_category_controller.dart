import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/categories/domain/usecases/delete_category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DeleteCategoryStatus { initial, loading, success, failure }

final class DeleteCategoryState {
  const DeleteCategoryState._({
    required this.status,
    this.categoryId,
    this.errorMessage,
  });

  const DeleteCategoryState.initial()
    : this._(status: DeleteCategoryStatus.initial);

  const DeleteCategoryState.loading(String categoryId)
    : this._(status: DeleteCategoryStatus.loading, categoryId: categoryId);

  const DeleteCategoryState.success()
    : this._(status: DeleteCategoryStatus.success);

  const DeleteCategoryState.failure(String message)
    : this._(status: DeleteCategoryStatus.failure, errorMessage: message);

  final DeleteCategoryStatus status;
  final String? categoryId;
  final String? errorMessage;
}

final deleteCategoryControllerProvider =
    NotifierProvider<DeleteCategoryController, DeleteCategoryState>(
      DeleteCategoryController.new,
    );

final class DeleteCategoryController extends Notifier<DeleteCategoryState> {
  late DeleteCategory _deleteCategory;

  @override
  DeleteCategoryState build() {
    _deleteCategory = ref.watch(deleteCategoryProvider);
    return const DeleteCategoryState.initial();
  }

  Future<void> delete(String categoryId) async {
    state = DeleteCategoryState.loading(categoryId);
    try {
      await _deleteCategory.execute(categoryId);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .categoryChanged(categoryId);
      state = const DeleteCategoryState.success();
    } on Object catch (error) {
      state = DeleteCategoryState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const DeleteCategoryState.initial();
  }
}
