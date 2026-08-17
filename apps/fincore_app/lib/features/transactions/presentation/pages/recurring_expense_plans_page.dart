import 'dart:async';

import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/categories/presentation/controllers/categories_controller.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/credit_cards_controller.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/presentation/controllers/customers_controller.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/formatters/payment_source_formatter.dart';
import 'package:fincore_app/features/transactions/presentation/providers/recurring_expense_plans_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _PlanAction { edit, delete }

final class RecurringExpensePlansPage extends ConsumerStatefulWidget {
  const RecurringExpensePlansPage({super.key});

  @override
  ConsumerState<RecurringExpensePlansPage> createState() =>
      _RecurringExpensePlansPageState();
}

final class _RecurringExpensePlansPageState
    extends ConsumerState<RecurringExpensePlansPage> {
  String? _deletingPlanId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReferences());
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(recurringExpensePlansProvider);
    final accounts = ref.watch(accountsControllerProvider).accounts;
    final cards = ref.watch(creditCardsControllerProvider).creditCards;
    final customers = ref.watch(customersControllerProvider).customers;
    final categories = ref.watch(categoriesControllerProvider).categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text(TransactionStrings.manageRecurringExpenses),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createManualExpense),
        icon: const Icon(Icons.add),
        label: const Text(TransactionStrings.createManualExpense),
      ),
      body: plans.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: ErrorMapper.map(error),
          retryLabel: TransactionStrings.retry,
          onRetry: () => ref.invalidate(recurringExpensePlansProvider),
        ),
        data: (items) => items.isEmpty
            ? const AppEmptyState(
                icon: Icons.event_repeat_outlined,
                title: TransactionStrings.noRecurringExpenses,
                description: TransactionStrings.noRecurringExpensesDescription,
              )
            : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        96,
                      ),
                      itemCount: items.length + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const AppCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline),
                                SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    TransactionStrings
                                        .recurringExpensesDescription,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final plan = items[index - 1];
                        final source = _sourceLabel(
                          plan,
                          accounts: accounts,
                          cards: cards,
                          customers: customers,
                        );
                        final category = categories
                            .where((item) => item.id == plan.categoryId)
                            .map((item) => item.name)
                            .firstOrNull;
                        return AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Icon(
                                plan.customerId == null
                                    ? Icons.event_repeat_outlined
                                    : Icons.person_outline,
                              ),
                            ),
                            title: Text(
                              plan.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${AppFormatters.date(plan.firstDueDate)} - '
                              '${AppFormatters.date(plan.dueDates.last)}\n'
                              '$source${category == null ? '' : ' • $category'}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${AppFormatters.currency(plan.amount, currencyCode: plan.currencyCode)}\n'
                                  '${plan.occurrenceCount} ay',
                                  textAlign: TextAlign.end,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                PopupMenuButton<_PlanAction>(
                                  enabled: _deletingPlanId != plan.id,
                                  onSelected: (action) =>
                                      _handleAction(plan, action),
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: _PlanAction.edit,
                                      child: ListTile(
                                        leading: Icon(Icons.edit_outlined),
                                        title: Text('Düzenle'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: _PlanAction.delete,
                                      child: ListTile(
                                        leading: Icon(Icons.delete_outline),
                                        title: Text('Sil'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _loadReferences() {
    final accountStatus = ref.read(accountsControllerProvider).status;
    if (accountStatus == AccountsStatus.initial ||
        accountStatus == AccountsStatus.failure) {
      unawaited(ref.read(accountsControllerProvider.notifier).load());
    }
    final cardStatus = ref.read(creditCardsControllerProvider).status;
    if (cardStatus == CreditCardsStatus.initial ||
        cardStatus == CreditCardsStatus.failure) {
      unawaited(ref.read(creditCardsControllerProvider.notifier).load());
    }
    final customerStatus = ref.read(customersControllerProvider).status;
    if (customerStatus == CustomersStatus.initial ||
        customerStatus == CustomersStatus.failure) {
      unawaited(ref.read(customersControllerProvider.notifier).load());
    }
    final categoryStatus = ref.read(categoriesControllerProvider).status;
    if (categoryStatus == CategoriesStatus.initial ||
        categoryStatus == CategoriesStatus.failure) {
      unawaited(ref.read(categoriesControllerProvider.notifier).load());
    }
  }

  Future<void> _handleAction(
    RecurringExpensePlan plan,
    _PlanAction action,
  ) async {
    if (action == _PlanAction.edit) {
      await context.push(AppRoutes.editRecurringExpenseLocation(plan.id));
      if (mounted) ref.invalidate(recurringExpensePlansProvider);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(TransactionStrings.deleteRecurringExpense),
        content: Text(
          '${plan.description}\n\n'
          '${TransactionStrings.deleteRecurringExpenseDescription}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(TransactionStrings.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(TransactionStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingPlanId = plan.id);
    try {
      await ref.read(deleteRecurringExpensePlanProvider).execute(plan.id);
      ref.read(appDataRefreshCoordinatorProvider).recurringExpensePlanChanged();
      ref.invalidate(recurringExpensePlansProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(TransactionStrings.recurringExpenseDeleted),
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(error))));
      }
    } finally {
      if (mounted) setState(() => _deletingPlanId = null);
    }
  }

  static String _sourceLabel(
    RecurringExpensePlan plan, {
    required List<Account> accounts,
    required List<CreditCard> cards,
    required List<Customer> customers,
  }) {
    for (final account in accounts) {
      if (account.id == plan.accountId) {
        return PaymentSourceFormatter.account(account);
      }
    }
    for (final card in cards) {
      if (card.id == plan.creditCardId) {
        return PaymentSourceFormatter.creditCard(card);
      }
    }
    for (final customer in customers) {
      if (customer.id == plan.customerId) return 'AH-${customer.name}';
    }
    return 'Kayıtlı ödeme kaynağı';
  }
}
