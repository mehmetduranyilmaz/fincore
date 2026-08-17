import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringExpensePlansProvider =
    FutureProvider<List<RecurringExpensePlan>>((ref) async {
      final plans =
          [
            ...await ref
                .watch(recurringExpensePlanRepositoryProvider)
                .getPlans(),
          ]..sort((left, right) {
            final dateComparison = left.firstDueDate.compareTo(
              right.firstDueDate,
            );
            return dateComparison != 0
                ? dateComparison
                : left.description.toLowerCase().compareTo(
                    right.description.toLowerCase(),
                  );
          });
      return List.unmodifiable(plans);
    });

final recurringExpensePlanProvider =
    FutureProvider.family<RecurringExpensePlan?, String>((ref, planId) async {
      final plans = await ref.watch(recurringExpensePlansProvider.future);
      for (final plan in plans) {
        if (plan.id == planId) return plan;
      }
      return null;
    });
