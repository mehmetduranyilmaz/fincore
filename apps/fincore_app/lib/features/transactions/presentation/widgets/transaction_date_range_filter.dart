import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transaction_filter_controller.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class TransactionDateRangeFilter extends ConsumerWidget {
  const TransactionDateRangeFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(
      transactionFilterControllerProvider.select(
        (filter) => (filter.startDate, filter.endDate),
      ),
    );
    final startDate = dateRange.$1;
    final endDate = dateRange.$2;
    final hasDateRange = startDate != null && endDate != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TransactionFilterChip(
          avatar: const Icon(Icons.date_range_outlined),
          label: hasDateRange
              ? '${AppFormatters.date(startDate)} – '
                    '${AppFormatters.date(endDate)}'
              : TransactionStrings.filterByDate,
          selected: hasDateRange,
          onSelected: (_) => _selectDateRange(
            context,
            ref,
            startDate: startDate,
            endDate: endDate,
          ),
        ),
        if (hasDateRange)
          IconButton(
            tooltip: TransactionStrings.clearDateFilter,
            onPressed: ref
                .read(transactionFilterControllerProvider.notifier)
                .clearDateRange,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }

  Future<void> _selectDateRange(
    BuildContext context,
    WidgetRef ref, {
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate, end: endDate)
          : null,
    );

    if (range != null) {
      ref
          .read(transactionFilterControllerProvider.notifier)
          .setDateRange(startDate: range.start, endDate: range.end);
    }
  }
}
