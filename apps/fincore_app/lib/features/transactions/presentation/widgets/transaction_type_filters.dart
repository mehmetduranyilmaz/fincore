import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transaction_filter_controller.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class TransactionTypeFilters extends ConsumerWidget {
  const TransactionTypeFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTypes = ref.watch(
      transactionFilterControllerProvider.select(
        (filter) => filter.transactionTypes,
      ),
    );

    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final type in TransactionType.values)
          TransactionFilterChip(
            label: TransactionStrings.transactionType(type),
            selected: selectedTypes.contains(type),
            onSelected: (_) => ref
                .read(transactionFilterControllerProvider.notifier)
                .toggleTransactionType(type),
          ),
      ],
    );
  }
}
