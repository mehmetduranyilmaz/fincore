import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/create_credit_card.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/create_credit_card_controller.dart';
import 'package:fincore_app/features/credit_cards/presentation/widgets/credit_card_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreateCreditCardPage extends ConsumerStatefulWidget {
  const CreateCreditCardPage({super.key});

  @override
  ConsumerState<CreateCreditCardPage> createState() =>
      _CreateCreditCardPageState();
}

final class _CreateCreditCardPageState
    extends ConsumerState<CreateCreditCardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(createCreditCardControllerProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createCreditCardControllerProvider);

    ref.listen<CreateCreditCardState>(createCreditCardControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == CreateCreditCardStatus.success && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(CreditCardStrings.create)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AppCard(
                child: CreditCardForm(
                  isLoading: state.status == CreateCreditCardStatus.loading,
                  errorMessage: state.errorMessage,
                  onCancel: () => context.pop(),
                  onSubmit: (value) => ref
                      .read(createCreditCardControllerProvider.notifier)
                      .create(
                        CreateCreditCardInput(
                          bankName: value.bankName,
                          cardName: value.cardName,
                          lastFourDigits: value.lastFourDigits,
                          creditLimit: value.creditLimit,
                          statementDay: value.statementDay,
                          dueDay: value.dueDay,
                          currencyCode: value.currencyCode,
                        ),
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
