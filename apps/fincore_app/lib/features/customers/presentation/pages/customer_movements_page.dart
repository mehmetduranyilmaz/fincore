import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/reporting/pdf_report_actions.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/customers/presentation/constants/customer_strings.dart';
import 'package:fincore_app/features/customers/domain/entities/customer_movement.dart';
import 'package:fincore_app/features/customers/presentation/providers/customer_balance_provider.dart';
import 'package:fincore_app/features/reports/presentation/financial_report_factories.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CustomerMovementsPage extends ConsumerWidget {
  const CustomerMovementsPage({required this.customerId, super.key});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customerProvider(customerId));
    final movements = ref.watch(customerMovementsProvider(customerId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          customer.value == null
              ? CustomerStrings.movements
              : '${customer.value!.name} • ${CustomerStrings.movements}',
        ),
        actions: [
          PdfReportActions(
            report:
                customer.value != null && movements.value?.isNotEmpty == true
                ? FinancialReportFactories.customerMovements(
                    customer: customer.value!,
                    movements: movements.value!,
                  )
                : null,
          ),
        ],
      ),
      body: movements.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: ErrorMapper.map(error),
          retryLabel: CustomerStrings.retry,
          onRetry: () => ref.invalidate(customerMovementsProvider(customerId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: CustomerStrings.noMovements,
              description: CustomerStrings.noMovementsDescription,
            );
          }
          final currencyCode = customer.value?.currencyCode ?? 'TRY';
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = items[index];
              final movement = item.transaction;
              final isCreditExpense = movement.isCustomerCreditExpense;
              final isCollection =
                  movement.isCustomerPayment &&
                  movement.customerBalanceDelta! < 0;
              final movementLabel = isCreditExpense
                  ? TransactionStrings.customerCreditExpense
                  : isCollection
                  ? CustomerStrings.collection
                  : CustomerStrings.payment;
              final sourceLabel = isCreditExpense
                  ? TransactionStrings.openAccount
                  : movement.accountId != null
                  ? 'Kasa/Banka'
                  : 'Kredi Kartı';
              return AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Icon(
                      isCreditExpense
                          ? Icons.receipt_long_outlined
                          : isCollection
                          ? Icons.call_received
                          : Icons.call_made,
                    ),
                  ),
                  title: Text(movement.merchant),
                  subtitle: Text(
                    '${AppFormatters.date(movement.transactionDate)} • '
                    '$movementLabel • $sourceLabel',
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.currency(
                          movement.customerBalanceDelta!.abs(),
                          currencyCode: currencyCode,
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${CustomerStrings.balance}: '
                        '${AppFormatters.currency(item.balanceAfterMovement.abs(), currencyCode: currencyCode)} '
                        '${_balanceCode(item.balanceSide)}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  onTap: () => context.push(
                    AppRoutes.transactionDetailsLocation(movement.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _balanceCode(CustomerBalanceSide side) {
    return switch (side) {
      CustomerBalanceSide.debtor => CustomerStrings.debtorCode,
      CustomerBalanceSide.creditor => CustomerStrings.creditorCode,
      CustomerBalanceSide.settled => CustomerStrings.settledCode,
    };
  }
}
