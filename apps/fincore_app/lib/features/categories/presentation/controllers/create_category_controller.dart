import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/categories/domain/usecases/create_category.dart';
import 'package:fincore_app/features/categories/domain/errors/category_operation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CreateCategoryStatus { initial, loading, success, failure }

final class CreateCategoryState {
  const CreateCategoryState._({required this.status, this.errorMessage});

  const CreateCategoryState.initial()
    : this._(status: CreateCategoryStatus.initial);

  const CreateCategoryState.loading()
    : this._(status: CreateCategoryStatus.loading);

  const CreateCategoryState.success()
    : this._(status: CreateCategoryStatus.success);

  const CreateCategoryState.failure(String message)
    : this._(status: CreateCategoryStatus.failure, errorMessage: message);

  final CreateCategoryStatus status;
  final String? errorMessage;
}

final createCategoryControllerProvider =
    NotifierProvider<CreateCategoryController, CreateCategoryState>(
      CreateCategoryController.new,
    );

final class CreateCategoryController extends Notifier<CreateCategoryState> {
  late CreateCategory _createCategory;

  @override
  CreateCategoryState build() {
    _createCategory = ref.watch(createCategoryProvider);
    return const CreateCategoryState.initial();
  }

  Future<void> create(CreateCategoryInput input) async {
    state = const CreateCategoryState.loading();
    try {
      final category = await _createCategory.execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .categoryCreated(category.id);
      state = const CreateCategoryState.success();
    } on CategoryOperationException catch (error) {
      state = CreateCategoryState.failure(error.message);
    } on Object catch (error) {
      state = CreateCategoryState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const CreateCategoryState.initial();
  }
}
