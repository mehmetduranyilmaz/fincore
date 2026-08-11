import 'dart:async';

import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/entities/customer_payment_input.dart';
import 'package:fincore_app/features/customers/presentation/constants/customer_strings.dart';
import 'package:fincore_app/features/customers/presentation/controllers/customer_commands_controller.dart';
import 'package:fincore_app/features/customers/presentation/controllers/customers_controller.dart';
import 'package:fincore_app/features/customers/presentation/providers/customer_balance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

final class _CustomersPageState extends ConsumerState<CustomersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(customersControllerProvider.notifier).load());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersControllerProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: CustomerStrings.title,
            action: FilledButton.icon(
              onPressed: () => context.push(AppRoutes.createCustomer),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text(CustomerStrings.add),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: _body(state)),
        ],
      ),
    );
  }

  Widget _body(CustomersState state) {
    return switch (state.status) {
      CustomersStatus.initial ||
      CustomersStatus.loading => const AppLoadingView(),
      CustomersStatus.failure => AppErrorView(
        message: state.errorMessage ?? CustomerStrings.unableToLoad,
        retryLabel: CustomerStrings.retry,
        onRetry: ref.read(customersControllerProvider.notifier).load,
      ),
      CustomersStatus.loaded when state.customers.isEmpty =>
        const AppEmptyState(
          icon: Icons.people_outline,
          title: CustomerStrings.noCustomers,
          description: CustomerStrings.noCustomersDescription,
        ),
      CustomersStatus.loaded => ListView.separated(
        itemCount: state.customers.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) =>
            _CustomerCard(customer: state.customers[index]),
      ),
    };
  }
}

final class _CustomerCard extends ConsumerWidget {
  const _CustomerCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(customerBalanceProvider(customer.id));
    final command = ref.watch(customerCommandsControllerProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  customer.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: CustomerStrings.movements,
                onPressed: () => context.push(
                  AppRoutes.customerMovementsLocation(customer.id),
                ),
                icon: const Icon(Icons.receipt_long_outlined),
              ),
              IconButton(
                tooltip: CustomerStrings.edit,
                onPressed: () =>
                    context.push(AppRoutes.editCustomerLocation(customer.id)),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: CustomerStrings.delete,
                onPressed: command.status == CustomerCommandStatus.loading
                    ? null
                    : () => _confirmDelete(context, ref),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          balance.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text(CustomerStrings.unableToLoad),
            data: (value) {
              final label = value > 0
                  ? CustomerStrings.receivable
                  : value < 0
                  ? CustomerStrings.payable
                  : CustomerStrings.balanced;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$label: ${AppFormatters.currency(value.abs(), currencyCode: customer.currencyCode)}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.push(
                          AppRoutes.customerPaymentLocation(
                            customer.id,
                            CustomerPaymentDirection.collect,
                          ),
                        ),
                        icon: const Icon(Icons.call_received),
                        label: const Text(CustomerStrings.collect),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push(
                          AppRoutes.customerPaymentLocation(
                            customer.id,
                            CustomerPaymentDirection.pay,
                          ),
                        ),
                        icon: const Icon(Icons.call_made),
                        label: const Text(CustomerStrings.pay),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(CustomerStrings.deleteTitle),
        content: const Text(CustomerStrings.deleteMessage),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(CustomerStrings.cancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text(CustomerStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await ref
        .read(customerCommandsControllerProvider.notifier)
        .deleteCustomer(customer.id);
    if (!deleted && context.mounted) {
      final message = ref.read(customerCommandsControllerProvider).errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}
