import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/features/accounts/presentation/constants/account_strings.dart';
import 'package:fincore_app/features/categories/presentation/constants/category_strings.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:flutter/material.dart';

final class TransactionDetailsView extends StatelessWidget {
  const TransactionDetailsView({required this.transaction, super.key});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _DetailRow(
            label: TransactionStrings.amount,
            value: AppFormatters.currency(
              transaction.isCustomerPayment
                  ? transaction.customerBalanceDelta!.abs()
                  : transaction.amount,
            ),
          ),
          if (transaction.isCustomerPayment)
            _DetailRow(
              label: 'Müşteri İşlemi',
              value: transaction.customerBalanceDelta! < 0
                  ? 'Tahsilat'
                  : 'Ödeme',
            ),
          _DetailRow(
            label: TransactionStrings.description,
            value: transaction.merchant,
          ),
          _DetailRow(
            label: TransactionStrings.date,
            value: AppFormatters.date(transaction.transactionDate),
          ),
          _DetailRow(
            label: transaction.accountId != null
                ? TransactionStrings.account
                : TransactionStrings.creditCard,
            value: transaction.accountId != null
                ? AccountStrings.nameFromId(transaction.accountId!)
                : TransactionStrings.creditCardName(transaction.creditCardId!),
          ),
          _DetailRow(
            label: TransactionStrings.type,
            value: TransactionStrings.transactionType(
              transaction.transactionType,
            ),
          ),
          _DetailRow(
            label: TransactionStrings.source,
            value: TransactionStrings.transactionSource(transaction.source),
            showDivider:
                transaction.categoryId != null || transaction.isInstallment,
          ),
          if (transaction.categoryId case final categoryId?)
            _DetailRow(
              label: TransactionStrings.category,
              value: CategoryStrings.nameFromId(categoryId),
              showDivider: false,
            ),
          if (transaction.isInstallment) ...[
            _DetailRow(
              label: TransactionStrings.installmentNumber,
              value: TransactionStrings.installmentLabel(
                transaction.installmentNumber!,
                transaction.installmentCount!,
              ),
            ),
            _DetailRow(
              label: TransactionStrings.originalAmount,
              value: AppFormatters.currency(
                transaction.installmentTotalAmount!,
              ),
              showDivider: false,
            ),
          ],
        ],
      ),
    );
  }
}

final class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(value)),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
