import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_balance_provider.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_statements_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreditCardStatementsPage extends ConsumerWidget {
  const CreditCardStatementsPage({required this.creditCardId, super.key});

  final String creditCardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(creditCardProvider(creditCardId));
    final statements = ref.watch(creditCardStatementsProvider(creditCardId));
    return Scaffold(
      appBar: AppBar(title: const Text(CreditCardStrings.statements)),
      body: card.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (creditCard) {
          if (creditCard == null) {
            return const Center(child: Text(CreditCardStrings.cardNotFound));
          }
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            creditCard.cardName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${creditCard.bankName} ••••${creditCard.lastFourDigits}',
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      key: const Key('create_statement_button'),
                      onPressed: creditCard.isArchived
                          ? null
                          : () => context.push(
                              AppRoutes.createCreditCardStatementLocation(
                                creditCardId,
                              ),
                            ),
                      icon: const Icon(Icons.add),
                      label: const Text(CreditCardStrings.createStatement),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: statements.when(
                    loading: () => const AppLoadingView(),
                    error: (error, stackTrace) => Center(
                      child: Text(CreditCardStrings.statementsUnableToLoad),
                    ),
                    data: (items) => items.isEmpty
                        ? const AppEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: CreditCardStrings.noStatements,
                            description:
                                CreditCardStrings.noStatementsDescription,
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final statement = items[index];
                              return AppCard(
                                child: Row(
                                  children: [
                                    const Icon(Icons.receipt_long_outlined),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${AppFormatters.date(statement.statementDate)} ekstresi',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            'Son ödeme: ${AppFormatters.date(statement.dueDate)} • '
                                            '${statement.lines.length} hareket',
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      AppFormatters.currency(
                                        statement.totalAmount,
                                        currencyCode: creditCard.currencyCode,
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
