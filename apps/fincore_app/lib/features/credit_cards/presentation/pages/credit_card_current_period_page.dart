import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_activity_summary_provider.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_balance_provider.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreditCardCurrentPeriodPage extends ConsumerWidget {
  const CreditCardCurrentPeriodPage({required this.creditCardId, super.key});

  final String creditCardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(creditCardProvider(creditCardId));
    final transactions = ref.watch(
      creditCardCurrentPeriodTransactionsProvider(creditCardId),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(CreditCardStrings.currentPeriodTransactions),
      ),
      body: card.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (creditCard) {
          if (creditCard == null) {
            return const Center(child: Text(CreditCardStrings.cardNotFound));
          }
          return transactions.when(
            loading: () => const AppLoadingView(),
            error: (error, stackTrace) => const Center(
              child: Text(CreditCardStrings.movementsUnableToLoad),
            ),
            data: (items) => Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryCard(
                        cardName:
                            '${creditCard.bankName} ${creditCard.cardName} '
                            '••••${creditCard.lastFourDigits}',
                        count: items.length,
                        total: _total(items),
                        currencyCode: creditCard.currencyCode,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: items.isEmpty
                            ? const AppEmptyState(
                                icon: Icons.sync_alt,
                                title: CreditCardStrings.noCurrentMovements,
                                description: CreditCardStrings
                                    .noCurrentMovementsDescription,
                              )
                            : ListView.separated(
                                key: const Key('current_period_list'),
                                itemCount: items.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final transaction = items[index];
                                  return AppCard(
                                    padding: EdgeInsets.zero,
                                    onTap: () => context.push(
                                      AppRoutes.transactionDetailsLocation(
                                        transaction.id,
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text(transaction.merchant),
                                      subtitle: Text(_subtitle(transaction)),
                                      trailing: Text(
                                        AppFormatters.currency(
                                          _signedAmount(transaction),
                                          currencyCode: creditCard.currencyCode,
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelLarge,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static double _total(List<Transaction> items) {
    return items.fold(0, (total, item) => total + _signedAmount(item));
  }

  static double _signedAmount(Transaction transaction) {
    return transaction.transactionType == TransactionType.expense
        ? transaction.amount.abs()
        : -transaction.amount.abs();
  }

  static String _subtitle(Transaction transaction) {
    final installment = transaction.isInstallment
        ? ' • ${transaction.installmentNumber}/${transaction.installmentCount} taksit'
        : '';
    return '${AppFormatters.date(transaction.transactionDate)}$installment';
  }
}

final class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.cardName,
    required this.count,
    required this.total,
    required this.currencyCode,
  });

  final String cardName;
  final int count;
  final double total;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cardName, style: Theme.of(context).textTheme.titleMedium),
                Text('$count hareket'),
              ],
            ),
          ),
          Text(
            AppFormatters.currency(total, currencyCode: currencyCode),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
