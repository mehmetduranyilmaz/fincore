import 'package:fincore_app/core/banking/turkish_bank.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart' as design_system;
import 'package:fincore_app/core/widgets/bank_icon.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_balance_provider.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_activity_summary_provider.dart';
import 'package:fincore_app/features/credit_cards/presentation/widgets/credit_card_activity_summary.dart';
import 'package:fincore_app/features/credit_cards/presentation/widgets/credit_card_balance_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class CreditCardCard extends ConsumerWidget {
  const CreditCardCard({
    required this.creditCard,
    required this.onEdit,
    required this.onDelete,
    required this.onPay,
    required this.onStatements,
    required this.onCurrentPeriod,
    required this.onFutureInstallments,
    this.isDeleting = false,
    super.key,
  });

  final CreditCard creditCard;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPay;
  final VoidCallback onStatements;
  final VoidCallback onCurrentPeriod;
  final VoidCallback onFutureInstallments;
  final bool isDeleting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final bank = TurkishBanks.findByName(creditCard.bankName);
    final balance = ref.watch(creditCardBalanceProvider(creditCard.id));
    final activity = ref.watch(
      creditCardActivitySummaryProvider(creditCard.id),
    );

    return design_system.AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (bank != null) ...[
                BankIcon(bank: bank, size: 36),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(creditCard.bankName, style: textTheme.titleMedium),
              ),
              if (creditCard.isArchived)
                Text(CreditCardStrings.archived, style: textTheme.labelMedium),
              IconButton(
                tooltip: CreditCardStrings.edit,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: CreditCardStrings.makePayment,
                onPressed: creditCard.isArchived ? null : onPay,
                icon: const Icon(Icons.payment_outlined),
              ),
              if (isDeleting)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  tooltip: CreditCardStrings.delete,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(creditCard.cardName, style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('****${creditCard.lastFourDigits}', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.md),
          balance.when(
            loading: () => const Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, stackTrace) => Text(
              CreditCardStrings.balanceUnavailable,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            data: (value) => CreditCardBalanceSummary(
              balance: value,
              creditLimit: creditCard.creditLimit,
              currencyCode: creditCard.currencyCode,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          activity.when(
            loading: () => const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, stackTrace) => const SizedBox.shrink(),
            data: (summary) => CreditCardActivitySummaryView(
              summary: summary,
              currencyCode: creditCard.currencyCode,
              onStatementsTap: onStatements,
              onCurrentPeriodTap: onCurrentPeriod,
              onFutureInstallmentsTap: onFutureInstallments,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${CreditCardStrings.statementDay}: '
                  '${creditCard.statementDay}',
                  style: textTheme.bodyMedium,
                ),
              ),
              Text(
                '${CreditCardStrings.dueDay}: ${creditCard.dueDay}',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
