import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/transactions/domain/usecases/convert_expense_to_installments.dart';
import 'package:fincore_app/features/transactions/domain/usecases/installment_calculator.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/convert_installments_controller.dart';
import 'package:fincore_app/features/transactions/presentation/providers/transaction_details_provider.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/installment_plan_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class ConvertInstallmentsPage extends ConsumerStatefulWidget {
  const ConvertInstallmentsPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  ConsumerState<ConvertInstallmentsPage> createState() =>
      _ConvertInstallmentsPageState();
}

final class _ConvertInstallmentsPageState
    extends ConsumerState<ConvertInstallmentsPage> {
  final _formKey = GlobalKey<FormState>();
  List<double> _amounts = const [];
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(convertInstallmentsControllerProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(transactionDetailsProvider(widget.transactionId));
    final state = ref.watch(convertInstallmentsControllerProvider);

    ref.listen<ConvertInstallmentsState>(
      convertInstallmentsControllerProvider,
      (previous, next) {
        if (next.status == ConvertInstallmentsStatus.success &&
            context.mounted) {
          context.pop();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(TransactionStrings.convertToInstallmentsTitle),
      ),
      body: details.when(
        loading: () => const AppLoadingView(),
        error: (_, _) => AppErrorView(
          message: TransactionStrings.unableToLoad,
          onRetry: () =>
              ref.invalidate(transactionDetailsProvider(widget.transactionId)),
        ),
        data: (transaction) {
          if (transaction == null || !transaction.canConvertToInstallments) {
            return const AppEmptyState(
              icon: Icons.credit_card_off_outlined,
              title: TransactionStrings.notFound,
              description: TransactionStrings.readOnlyDescription,
            );
          }
          final isLoading = state.status == ConvertInstallmentsStatus.loading;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            transaction.merchant,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${TransactionStrings.originalAmount}: '
                            '${AppFormatters.currency(transaction.amount)}',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          InstallmentPlanEditor(
                            totalAmount: transaction.amount,
                            initialCount: 2,
                            minimumCount: 2,
                            enabled: !isLoading,
                            onChanged: (values) => _amounts = values,
                          ),
                          if (_validationMessage case final message?) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              message,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          if (state.errorMessage case final message?) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              message,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => context.pop(),
                                  child: const Text(TransactionStrings.cancel),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppButton(
                                  label:
                                      TransactionStrings.convertToInstallments,
                                  isLoading: isLoading,
                                  onPressed: () => _submit(transaction.amount),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(double totalAmount) async {
    setState(() => _validationMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    try {
      InstallmentCalculator.validateCustomAmounts(totalAmount, _amounts);
    } on ArgumentError {
      setState(
        () => _validationMessage = TransactionStrings.installmentTotalMismatch,
      );
      return;
    }
    await ref
        .read(convertInstallmentsControllerProvider.notifier)
        .convert(
          ConvertExpenseToInstallmentsInput(
            transactionId: widget.transactionId,
            installmentAmounts: _amounts,
          ),
        );
  }
}
