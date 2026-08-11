import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_activity_summary.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:flutter/material.dart';

final class CreditCardActivitySummaryView extends StatelessWidget {
  const CreditCardActivitySummaryView({
    required this.summary,
    required this.currencyCode,
    required this.onStatementsTap,
    required this.onCurrentPeriodTap,
    required this.onFutureInstallmentsTap,
    super.key,
  });

  final CreditCardActivitySummary summary;
  final String currencyCode;
  final VoidCallback onStatementsTap;
  final VoidCallback onCurrentPeriodTap;
  final VoidCallback onFutureInstallmentsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _item(
          context,
          Icons.receipt_long_outlined,
          CreditCardStrings.statements,
          summary.statementAmount,
          onTap: onStatementsTap,
        ),
        const SizedBox(width: AppSpacing.sm),
        _item(
          context,
          Icons.sync_alt,
          CreditCardStrings.currentPeriodTransactions,
          summary.currentPeriodAmount,
          onTap: onCurrentPeriodTap,
        ),
        const SizedBox(width: AppSpacing.sm),
        _item(
          context,
          Icons.calendar_month_outlined,
          CreditCardStrings.futureInstallments,
          summary.futureInstallmentAmount,
          onTap: onFutureInstallmentsTap,
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String tooltip,
    double amount, {
    VoidCallback? onTap,
  }) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              child: Text(
                AppFormatters.currency(amount, currencyCode: currencyCode),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: onTap == null
            ? content
            : Semantics(
                button: true,
                label: tooltip,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap,
                  child: content,
                ),
              ),
      ),
    );
  }
}
