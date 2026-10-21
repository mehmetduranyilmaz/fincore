import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/reporting/pdf_report_actions.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/presentation/constants/customer_strings.dart';
import 'package:fincore_app/features/customers/domain/entities/customer_movement.dart';
import 'package:fincore_app/features/customers/presentation/providers/customer_balance_provider.dart';
import 'package:fincore_app/features/reports/presentation/financial_report_factories.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_occurrence.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CustomerMovementsPage extends ConsumerStatefulWidget {
  const CustomerMovementsPage({required this.customerId, super.key});

  final String customerId;

  @override
  ConsumerState<CustomerMovementsPage> createState() =>
      _CustomerMovementsPageState();
}

final class _CustomerMovementsPageState
    extends ConsumerState<CustomerMovementsPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _hasDateRange => _startDate != null || _endDate != null;

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(customerProvider(widget.customerId));
    final movements = ref.watch(customerMovementsProvider(widget.customerId));
    final allItems = movements.value;
    final filteredItems = allItems == null ? null : _filter(allItems);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          customer.value == null
              ? CustomerStrings.movements
              : '${customer.value!.name} • ${CustomerStrings.movements}',
        ),
        actions: [
          PdfReportActions(
            report: customer.value != null && filteredItems?.isNotEmpty == true
                ? FinancialReportFactories.customerMovements(
                    customer: customer.value!,
                    movements: filteredItems!,
                    currentBalance: _currentBalance(customer.value!, allItems!),
                    startDate: _startDate,
                    endDate: _endDate,
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
          onRetry: () =>
              ref.invalidate(customerMovementsProvider(widget.customerId)),
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
          final visible = _filter(items);
          final carriedBalance = _carriedBalance(customer.value, items);
          final currentBalance = items.last.balanceAfterMovement;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _buildDateRangeFilter(),
              const SizedBox(height: AppSpacing.md),
              if (carriedBalance != null) ...[
                _BalanceLine(
                  key: const Key('customer_movements_carried_balance'),
                  label: CustomerStrings.carriedBalance,
                  balance: carriedBalance,
                  currencyCode: currencyCode,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    CustomerStrings.noMovementsInRange,
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final item in visible) ...[
                _MovementCard(item: item, currencyCode: currencyCode),
                const SizedBox(height: AppSpacing.md),
              ],
              AppCard(
                key: const Key('customer_movements_current_balance'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BalanceLine(
                      label: CustomerStrings.currentBalance,
                      balance: currentBalance,
                      currencyCode: currencyCode,
                      emphasized: true,
                    ),
                    if (_hasDateRange) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        CustomerStrings.currentBalanceNote,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          key: const Key('customer_movements_date_range'),
          onPressed: _selectDateRange,
          icon: const Icon(Icons.date_range_outlined),
          label: Text(
            _hasDateRange
                ? '${AppFormatters.date(_startDate!)} - '
                      '${AppFormatters.date(_endDate!)}'
                : CustomerStrings.allDates,
          ),
        ),
        if (_hasDateRange)
          IconButton(
            key: const Key('customer_movements_clear_date_range'),
            tooltip: CustomerStrings.clearDateRange,
            onPressed: () => setState(() {
              _startDate = null;
              _endDate = null;
            }),
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10, 12, 31),
      initialDateRange: _hasDateRange
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime(now.year, now.month),
              end: DateUtils.dateOnly(now),
            ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _startDate = DateUtils.dateOnly(selected.start);
      _endDate = DateUtils.dateOnly(selected.end);
    });
  }

  List<CustomerMovement> _filter(List<CustomerMovement> items) {
    if (!_hasDateRange) return items;
    return [
      for (final item in items)
        if (_isInRange(DateUtils.dateOnly(item.transaction.transactionDate)))
          item,
    ];
  }

  bool _isInRange(DateTime date) =>
      (_startDate == null || !date.isBefore(_startDate!)) &&
      (_endDate == null || !date.isAfter(_endDate!));

  /// Balance brought forward into the selected range; null when unfiltered.
  double? _carriedBalance(Customer? customer, List<CustomerMovement> items) {
    final start = _startDate;
    if (start == null) return null;
    final before = items.where(
      (item) =>
          DateUtils.dateOnly(item.transaction.transactionDate).isBefore(start),
    );
    return before.isEmpty
        ? customer?.openingBalance ?? 0
        : before.last.balanceAfterMovement;
  }

  static double _currentBalance(
    Customer customer,
    List<CustomerMovement> items,
  ) =>
      items.isEmpty ? customer.openingBalance : items.last.balanceAfterMovement;
}

final class _MovementCard extends StatelessWidget {
  const _MovementCard({required this.item, required this.currencyCode});

  final CustomerMovement item;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final movement = item.transaction;
    final isCreditExpense = movement.isCustomerCreditExpense;
    final isCollection =
        movement.isCustomerPayment && movement.customerBalanceDelta! < 0;
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
    final dueDate = RecurringExpenseOccurrence.dueDateOf(movement.id);
    final dueLabel =
        dueDate != null &&
            !DateUtils.isSameDay(dueDate, movement.transactionDate)
        ? ' • ${TransactionStrings.dueDate}: ${AppFormatters.date(dueDate)}'
        : '';
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
          '$movementLabel • $sourceLabel$dueLabel',
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
              '${_formatBalance(item.balanceAfterMovement, currencyCode)}',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        onTap: () =>
            context.push(AppRoutes.transactionDetailsLocation(movement.id)),
      ),
    );
  }
}

final class _BalanceLine extends StatelessWidget {
  const _BalanceLine({
    required this.label,
    required this.balance,
    required this.currencyCode,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final double balance;
  final String currencyCode;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasized
        ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(_formatBalance(balance, currencyCode), style: style),
      ],
    );
  }
}

String _formatBalance(double balance, String currencyCode) =>
    '${AppFormatters.currency(balance.abs(), currencyCode: currencyCode)} '
    '${_balanceCode(balance)}';

String _balanceCode(double balance) {
  if (balance > 0) return CustomerStrings.debtorCode;
  if (balance < 0) return CustomerStrings.creditorCode;
  return CustomerStrings.settledCode;
}
