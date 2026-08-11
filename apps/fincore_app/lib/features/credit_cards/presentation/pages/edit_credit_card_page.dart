import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/update_credit_card.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/credit_cards_controller.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/edit_credit_card_controller.dart';
import 'package:fincore_app/features/credit_cards/presentation/widgets/credit_card_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class EditCreditCardPage extends ConsumerStatefulWidget {
  const EditCreditCardPage({required this.creditCardId, super.key});

  final String creditCardId;

  @override
  ConsumerState<EditCreditCardPage> createState() => _EditCreditCardPageState();
}

final class _EditCreditCardPageState extends ConsumerState<EditCreditCardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(editCreditCardControllerProvider.notifier).reset();
      if (ref.read(creditCardsControllerProvider).status ==
          CreditCardsStatus.initial) {
        ref.read(creditCardsControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final creditCards = ref.watch(creditCardsControllerProvider);
    final editState = ref.watch(editCreditCardControllerProvider);

    ref.listen<EditCreditCardState>(editCreditCardControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == EditCreditCardStatus.success && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(CreditCardStrings.edit)),
      body: _body(creditCards, editState),
    );
  }

  Widget _body(CreditCardsState state, EditCreditCardState editState) {
    if (state.status == CreditCardsStatus.initial ||
        state.status == CreditCardsStatus.loading) {
      return const AppLoadingView();
    }
    if (state.status == CreditCardsStatus.failure) {
      return AppErrorView(
        message: state.errorMessage ?? CreditCardStrings.unableToLoad,
        onRetry: ref.read(creditCardsControllerProvider.notifier).load,
      );
    }

    CreditCard? selected;
    for (final creditCard in state.creditCards) {
      if (creditCard.id == widget.creditCardId) {
        selected = creditCard;
        break;
      }
    }
    if (selected == null) {
      return AppErrorView(
        message: CreditCardStrings.cardNotFound,
        onRetry: ref.read(creditCardsControllerProvider.notifier).load,
      );
    }
    final creditCard = selected;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AppCard(
              child: CreditCardForm(
                key: ValueKey(creditCard.id),
                initialValue: CreditCardFormValue(
                  bankName: creditCard.bankName,
                  cardName: creditCard.cardName,
                  lastFourDigits: creditCard.lastFourDigits,
                  creditLimit: creditCard.creditLimit,
                  statementDay: creditCard.statementDay,
                  dueDay: creditCard.dueDay,
                  currencyCode: creditCard.currencyCode,
                  isArchived: creditCard.isArchived,
                ),
                showArchiveOption: true,
                isLoading: editState.status == EditCreditCardStatus.loading,
                errorMessage: editState.errorMessage,
                onCancel: () => context.pop(),
                onSubmit: (value) => ref
                    .read(editCreditCardControllerProvider.notifier)
                    .update(
                      UpdateCreditCardInput(
                        id: creditCard.id,
                        bankName: value.bankName,
                        cardName: value.cardName,
                        lastFourDigits: value.lastFourDigits,
                        creditLimit: value.creditLimit,
                        statementDay: value.statementDay,
                        dueDay: value.dueDay,
                        currencyCode: value.currencyCode,
                        isArchived: value.isArchived,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
