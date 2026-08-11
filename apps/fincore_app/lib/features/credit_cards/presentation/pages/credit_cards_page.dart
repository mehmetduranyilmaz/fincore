import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/credit_cards_controller.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/delete_credit_card_controller.dart';
import 'package:fincore_app/features/credit_cards/presentation/widgets/credit_cards_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreditCardsPage extends ConsumerStatefulWidget {
  const CreditCardsPage({super.key});

  @override
  ConsumerState<CreditCardsPage> createState() => _CreditCardsPageState();
}

final class _CreditCardsPageState extends ConsumerState<CreditCardsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(creditCardsControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creditCardsControllerProvider);
    final deleteState = ref.watch(deleteCreditCardControllerProvider);

    ref.listen<DeleteCreditCardState>(deleteCreditCardControllerProvider, (
      previous,
      next,
    ) {
      final message = next.errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return switch (state.status) {
      CreditCardsStatus.initial ||
      CreditCardsStatus.loading => const AppLoadingView(),
      CreditCardsStatus.loaded => _CreditCardsContent(
        creditCards: state.creditCards,
        deletingCreditCardId:
            deleteState.status == DeleteCreditCardStatus.loading
            ? deleteState.creditCardId
            : null,
        onCreate: () => context.push(AppRoutes.createCreditCard),
        onPaymentCalendar: () =>
            context.push(AppRoutes.creditCardPaymentCalendar),
        onEdit: (creditCard) =>
            context.push(AppRoutes.editCreditCardLocation(creditCard.id)),
        onDelete: _confirmDelete,
        onPay: (creditCard) =>
            context.push(AppRoutes.creditCardPaymentLocation(creditCard.id)),
        onStatements: (creditCard) =>
            context.push(AppRoutes.creditCardStatementsLocation(creditCard.id)),
        onCurrentPeriod: (creditCard) => context.push(
          AppRoutes.creditCardCurrentPeriodLocation(creditCard.id),
        ),
        onFutureInstallments: (creditCard) => context.push(
          AppRoutes.creditCardFutureInstallmentsLocation(creditCard.id),
        ),
      ),
      CreditCardsStatus.failure => AppErrorView(
        message: state.errorMessage ?? CreditCardStrings.unableToLoad,
        retryLabel: CreditCardStrings.retry,
        onRetry: ref.read(creditCardsControllerProvider.notifier).load,
      ),
    };
  }

  Future<void> _confirmDelete(CreditCard creditCard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(CreditCardStrings.deleteTitle),
        content: Text(
          '${creditCard.bankName} ${creditCard.cardName}\n\n'
          '${CreditCardStrings.deleteMessage}',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(CreditCardStrings.cancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text(CreditCardStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(deleteCreditCardControllerProvider.notifier)
          .delete(creditCard.id);
    }
  }
}

final class _CreditCardsContent extends StatelessWidget {
  const _CreditCardsContent({
    required this.creditCards,
    required this.onCreate,
    required this.onPaymentCalendar,
    required this.onEdit,
    required this.onDelete,
    required this.onPay,
    required this.onStatements,
    required this.onCurrentPeriod,
    required this.onFutureInstallments,
    this.deletingCreditCardId,
  });

  final List<CreditCard> creditCards;
  final VoidCallback onCreate;
  final VoidCallback onPaymentCalendar;
  final ValueChanged<CreditCard> onEdit;
  final ValueChanged<CreditCard> onDelete;
  final ValueChanged<CreditCard> onPay;
  final ValueChanged<CreditCard> onStatements;
  final ValueChanged<CreditCard> onCurrentPeriod;
  final ValueChanged<CreditCard> onFutureInstallments;
  final String? deletingCreditCardId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: CreditCardStrings.title,
            action: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text(CreditCardStrings.create),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onPaymentCalendar,
            icon: const Icon(Icons.calendar_view_month_outlined),
            label: const Text(CreditCardStrings.paymentCalendar),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: creditCards.isEmpty
                ? const AppEmptyState(
                    icon: Icons.credit_card_off_outlined,
                    title: CreditCardStrings.noCreditCards,
                    description: CreditCardStrings.noCreditCardsDescription,
                  )
                : CreditCardsList(
                    creditCards: creditCards,
                    deletingCreditCardId: deletingCreditCardId,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onPay: onPay,
                    onStatements: onStatements,
                    onCurrentPeriod: onCurrentPeriod,
                    onFutureInstallments: onFutureInstallments,
                  ),
          ),
        ],
      ),
    );
  }
}
