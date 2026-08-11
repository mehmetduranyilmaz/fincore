import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:flutter/material.dart';

final class TransactionsList extends StatelessWidget {
  const TransactionsList({
    required this.transactions,
    this.onTransactionTap,
    super.key,
  });

  static const double _desktopBreakpoint = 720;

  final List<Transaction> transactions;
  final ValueChanged<Transaction>? onTransactionTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _desktopBreakpoint) {
          return SingleChildScrollView(
            key: const Key('transactions_column_layout'),
            child: Column(
              children: [
                for (final (index, transaction) in transactions.indexed) ...[
                  TransactionCard(
                    transaction: transaction,
                    onTap: onTransactionTap == null
                        ? null
                        : () => onTransactionTap!(transaction),
                  ),
                  if (index < transactions.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          );
        }

        return ListView.separated(
          key: const Key('transactions_desktop_list_layout'),
          itemCount: transactions.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: TransactionCard(
                  transaction: transactions[index],
                  onTap: onTransactionTap == null
                      ? null
                      : () => onTransactionTap!(transactions[index]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
