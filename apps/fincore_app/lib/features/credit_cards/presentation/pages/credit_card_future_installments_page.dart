import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_activity_summary_provider.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_balance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreditCardFutureInstallmentsPage extends ConsumerWidget {
  const CreditCardFutureInstallmentsPage({
    required this.creditCardId,
    super.key,
  });

  final String creditCardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(creditCardProvider(creditCardId));
    return Scaffold(
      appBar: AppBar(title: const Text(CreditCardStrings.futureInstallments)),
      body: card.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (creditCard) {
          if (creditCard == null) {
            return const Center(child: Text(CreditCardStrings.cardNotFound));
          }
          final installments = ref.watch(
            creditCardFutureInstallmentsProvider(creditCard.id),
          );
          return installments.when(
            loading: () => const AppLoadingView(),
            error: (error, stackTrace) => const Center(
              child: Text(CreditCardStrings.installmentsUnableToLoad),
            ),
            data: (items) => Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${creditCard.bankName} ${creditCard.cardName} '
                                    '••••${creditCard.lastFourDigits}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'Henüz dönem içine yansımamış '
                                    '${items.length} taksit',
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppFormatters.currency(
                                items.fold(
                                  0,
                                  (total, item) => total + item.amount.abs(),
                                ),
                                currencyCode: creditCard.currencyCode,
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: items.isEmpty
                            ? const AppEmptyState(
                                icon: Icons.calendar_month_outlined,
                                title: CreditCardStrings.noFutureInstallments,
                                description: CreditCardStrings
                                    .noFutureInstallmentsDescription,
                              )
                            : ListView.separated(
                                key: const Key('future_installments_list'),
                                itemCount: items.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final installment = items[index];
                                  return AppCard(
                                    padding: EdgeInsets.zero,
                                    onTap: () => context.push(
                                      AppRoutes.transactionDetailsLocation(
                                        installment.id,
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text(installment.merchant),
                                      subtitle: Text(
                                        '${installment.installmentNumber}/'
                                        '${installment.installmentCount} taksit • '
                                        '${AppFormatters.date(installment.transactionDate)}',
                                      ),
                                      trailing: Text(
                                        AppFormatters.currency(
                                          installment.amount.abs(),
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
}
