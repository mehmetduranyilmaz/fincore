import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/categories/domain/usecases/update_category.dart';
import 'package:fincore_app/features/categories/domain/errors/category_operation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UpdateCategoryStatus { initial, loading, success, failure }

final class UpdateCategoryState {
  const UpdateCategoryState._({required this.status, this.errorMessage});

  const UpdateCategoryState.initial()
    : this._(status: UpdateCategoryStatus.initial);

  const UpdateCategoryState.loading()
    : this._(status: UpdateCategoryStatus.loading);

  const UpdateCategoryState.success()
    : this._(status: UpdateCategoryStatus.success);

  const UpdateCategoryState.failure(String message)
    : this._(status: UpdateCategoryStatus.failure, errorMessage: message);

  final UpdateCategoryStatus status;
  final String? errorMessage;
}

final updateCategoryControllerProvider =
    NotifierProvider<UpdateCategoryController, UpdateCategoryState>(
      UpdateCategoryController.new,
    );

final class UpdateCategoryController extends Notifier<UpdateCategoryState> {
  late UpdateCategory _updateCategory;

  @override
  UpdateCategoryState build() {
    _updateCategory = ref.watch(updateCategoryProvider);
    return const UpdateCategoryState.initial();
  }

  Future<void> update(UpdateCategoryInput input) async {
    state = const UpdateCategoryState.loading();
    try {
      final category = await _updateCategory.execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .categoryChanged(category.id);
      state = const UpdateCategoryState.success();
    } on CategoryOperationException catch (error) {
      state = UpdateCategoryState.failure(error.message);
    } on Object catch (error) {
      state = UpdateCategoryState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const UpdateCategoryState.initial();
  }
}
