import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/presentation/widgets/credit_card_card.dart';
import 'package:flutter/material.dart';

final class CreditCardsList extends StatelessWidget {
  const CreditCardsList({
    required this.creditCards,
    required this.onEdit,
    required this.onDelete,
    required this.onPay,
    required this.onStatements,
    required this.onCurrentPeriod,
    required this.onFutureInstallments,
    this.deletingCreditCardId,
    super.key,
  });

  static const double _gridBreakpoint = 720;

  final List<CreditCard> creditCards;
  final ValueChanged<CreditCard>? onEdit;
  final ValueChanged<CreditCard>? onDelete;
  final ValueChanged<CreditCard>? onPay;
  final ValueChanged<CreditCard>? onStatements;
  final ValueChanged<CreditCard>? onCurrentPeriod;
  final ValueChanged<CreditCard>? onFutureInstallments;
  final String? deletingCreditCardId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _gridBreakpoint) {
          return SingleChildScrollView(
            key: const Key('credit_cards_column_layout'),
            child: Column(
              children: [
                for (final (index, creditCard) in creditCards.indexed) ...[
                  _card(creditCard),
                  if (index < creditCards.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          );
        }

        return GridView.builder(
          key: const Key('credit_cards_grid_layout'),
          itemCount: creditCards.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 560,
            mainAxisExtent: 392,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) => _card(creditCards[index]),
        );
      },
    );
  }

  Widget _card(CreditCard creditCard) {
    return CreditCardCard(
      creditCard: creditCard,
      isDeleting: deletingCreditCardId == creditCard.id,
      onEdit: () => onEdit?.call(creditCard),
      onDelete: () => onDelete?.call(creditCard),
      onPay: () => onPay?.call(creditCard),
      onStatements: () => onStatements?.call(creditCard),
      onCurrentPeriod: () => onCurrentPeriod?.call(creditCard),
      onFutureInstallments: () => onFutureInstallments?.call(creditCard),
    );
  }
}
