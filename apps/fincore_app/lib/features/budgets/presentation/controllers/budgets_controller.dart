import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/budgets/domain/entities/budget.dart';
import 'package:fincore_app/features/budgets/domain/entities/budget_progress.dart';
import 'package:fincore_app/features/budgets/domain/usecases/calculate_budget_progress.dart';
import 'package:fincore_app/features/budgets/domain/usecases/get_budgets.dart';
import 'package:fincore_app/features/budgets/presentation/constants/budget_strings.dart';
import 'package:fincore_app/features/categories/domain/usecases/get_categories.dart';
import 'package:fincore_app/features/categories/presentation/constants/category_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BudgetsStatus { initial, loading, loaded, failure }

final class BudgetViewData {
  const BudgetViewData({
    required this.budget,
    required this.categoryName,
    required this.progress,
  });

  final Budget budget;
  final String categoryName;
  final BudgetProgress progress;
}

final class BudgetsState {
  const BudgetsState._({
    required this.status,
    this.items = const [],
    this.errorMessage,
  });

  const BudgetsState.initial() : this._(status: BudgetsStatus.initial);

  const BudgetsState.loading() : this._(status: BudgetsStatus.loading);

  BudgetsState.loaded(List<BudgetViewData> items)
    : this._(status: BudgetsStatus.loaded, items: List.unmodifiable(items));

  const BudgetsState.failure(String message)
    : this._(status: BudgetsStatus.failure, errorMessage: message);

  final BudgetsStatus status;
  final List<BudgetViewData> items;
  final String? errorMessage;
}

final budgetsControllerProvider =
    NotifierProvider<BudgetsController, BudgetsState>(BudgetsController.new);

final class BudgetsController extends Notifier<BudgetsState> {
  late GetBudgetsUseCase _getBudgets;
  late GetCategories _getCategories;
  late CalculateBudgetProgressUseCase _calculateProgress;
  int _requestId = 0;

  @override
  BudgetsState build() {
    _getBudgets = ref.watch(getBudgetsProvider);
    _getCategories = ref.watch(getCategoriesProvider);
    _calculateProgress = ref.watch(calculateBudgetProgressProvider);
    return const BudgetsState.initial();
  }

  Future<void> load() async {
    final requestId = ++_requestId;
    state = const BudgetsState.loading();

    try {
      final budgetsFuture = _getBudgets.execute();
      final categoriesFuture = _getCategories.execute();
      final budgets = await budgetsFuture;
      final categories = await categoriesFuture;
      final categoryNames = {
        for (final category in categories)
          category.id: CategoryStrings.displayName(category.name),
      };
      final progressValues = await Future.wait(
        budgets.map(_calculateProgress.execute),
      );
      final items = [
        for (var index = 0; index < budgets.length; index++)
          BudgetViewData(
            budget: budgets[index],
            categoryName:
                categoryNames[budgets[index].categoryId] ??
                BudgetStrings.deletedCategory,
            progress: progressValues[index],
          ),
      ];

      if (ref.mounted && requestId == _requestId) {
        state = BudgetsState.loaded(items);
      }
    } on Object catch (error) {
      if (ref.mounted && requestId == _requestId) {
        state = BudgetsState.failure(ErrorMapper.map(error));
      }
    }
  }
}
