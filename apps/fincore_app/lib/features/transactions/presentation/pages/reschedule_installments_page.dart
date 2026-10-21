import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/usecases/reschedule_installments.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/reschedule_installments_controller.dart';
import 'package:fincore_app/features/transactions/presentation/providers/transaction_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class RescheduleInstallmentsPage extends ConsumerStatefulWidget {
  const RescheduleInstallmentsPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  ConsumerState<RescheduleInstallmentsPage> createState() =>
      _RescheduleInstallmentsPageState();
}

final class _RescheduleInstallmentsPageState
    extends ConsumerState<RescheduleInstallmentsPage> {
  final Map<String, DateTime> _dates = {};
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(rescheduleInstallmentsControllerProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(transactionDetailsProvider(widget.transactionId));
    final state = ref.watch(rescheduleInstallmentsControllerProvider);

    ref.listen<RescheduleInstallmentsState>(
      rescheduleInstallmentsControllerProvider,
      (previous, next) {
        if (next.status == RescheduleInstallmentsStatus.success &&
            context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(TransactionStrings.installmentDatesUpdated),
            ),
          );
          context.pop();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(TransactionStrings.rescheduleInstallments),
      ),
      body: details.when(
        loading: () => const AppLoadingView(),
        error: (_, _) => AppErrorView(
          message: TransactionStrings.unableToLoad,
          onRetry: () =>
              ref.invalidate(transactionDetailsProvider(widget.transactionId)),
        ),
        data: (transaction) {
          final planId = transaction?.installmentPlanId;
          if (transaction == null || planId == null) {
            return const AppEmptyState(
              icon: Icons.event_busy_outlined,
              title: TransactionStrings.notFound,
              description: TransactionStrings.readOnlyDescription,
            );
          }
          return ref
              .watch(installmentPlanScheduleProvider(planId))
              .when(
                loading: () => const AppLoadingView(),
                error: (_, _) => AppErrorView(
                  message: TransactionStrings.unableToLoad,
                  onRetry: () =>
                      ref.invalidate(installmentPlanScheduleProvider(planId)),
                ),
                data: (schedule) => _buildForm(
                  context,
                  transaction: transaction,
                  schedule: schedule,
                  isLoading:
                      state.status == RescheduleInstallmentsStatus.loading,
                  errorMessage: state.errorMessage,
                ),
              );
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required Transaction transaction,
    required InstallmentPlanSchedule schedule,
    required bool isLoading,
    required String? errorMessage,
  }) {
    final colors = Theme.of(context).colorScheme;
    final hasEditable = schedule.reschedulableIds.isNotEmpty;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AppCard(
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
                    '${AppFormatters.currency(transaction.installmentTotalAmount!)}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    hasEditable
                        ? TransactionStrings.rescheduleInstallmentsHint
                        : TransactionStrings.noReschedulableInstallments,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final item in schedule.installments)
                    _InstallmentDateRow(
                      key: Key('installment_date_${item.id}'),
                      installment: item,
                      date: _dates[item.id] ?? item.transactionDate,
                      editable:
                          !isLoading &&
                          schedule.reschedulableIds.contains(item.id),
                      onTap: () => _pickDate(item, schedule),
                    ),
                  if (_validationMessage ?? errorMessage case final message?)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        message,
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : () => context.pop(),
                          child: const Text(TransactionStrings.cancel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: TransactionStrings.save,
                          isLoading: isLoading,
                          onPressed: hasEditable && _dates.isNotEmpty
                              ? () => _submit(schedule)
                              : null,
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
    );
  }

  Future<void> _pickDate(
    Transaction installment,
    InstallmentPlanSchedule schedule,
  ) async {
    // Keep the plan ordered: the picker only offers days between the
    // neighbouring installments and after the latest cut statement.
    final index = schedule.installments.indexOf(installment);
    DateTime dateAt(int i) => DateUtils.dateOnly(
      _dates[schedule.installments[i].id] ??
          schedule.installments[i].transactionDate,
    );
    var firstDate = schedule.earliestDate ?? DateTime(2000);
    if (index > 0) {
      final afterPrevious = DateUtils.addDaysToDate(dateAt(index - 1), 1);
      if (afterPrevious.isAfter(firstDate)) firstDate = afterPrevious;
    }
    final lastDate = index < schedule.installments.length - 1
        ? DateUtils.addDaysToDate(dateAt(index + 1), -1)
        : DateTime(DateTime.now().year + 10, 12, 31);
    if (lastDate.isBefore(firstDate)) {
      setState(
        () => _validationMessage = TransactionStrings.installmentDatesOrder,
      );
      return;
    }
    final current = dateAt(index);
    final selected = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: current.isBefore(firstDate)
          ? firstDate
          : current.isAfter(lastDate)
          ? lastDate
          : current,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _validationMessage = null;
      _dates[installment.id] = selected;
    });
  }

  Future<void> _submit(InstallmentPlanSchedule schedule) async {
    final dates = [
      for (final item in schedule.installments)
        _dates[item.id] ?? item.transactionDate,
    ];
    for (var index = 1; index < dates.length; index++) {
      final previous = DateUtils.dateOnly(dates[index - 1]);
      if (!DateUtils.dateOnly(dates[index]).isAfter(previous)) {
        setState(
          () => _validationMessage = TransactionStrings.installmentDatesOrder,
        );
        return;
      }
    }
    await ref
        .read(rescheduleInstallmentsControllerProvider.notifier)
        .reschedule(
          RescheduleInstallmentsInput(
            installmentPlanId: schedule.installments.first.installmentPlanId!,
            datesByTransactionId: Map.of(_dates),
          ),
          previous: schedule.installments,
        );
  }
}

final class _InstallmentDateRow extends StatelessWidget {
  const _InstallmentDateRow({
    required this.installment,
    required this.date,
    required this.editable,
    required this.onTap,
    super.key,
  });

  final Transaction installment;
  final DateTime date;
  final bool editable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        TransactionStrings.installmentLabel(
          installment.installmentNumber!,
          installment.installmentCount!,
        ),
      ),
      subtitle: Text(
        editable
            ? AppFormatters.currency(installment.amount.abs())
            : '${AppFormatters.currency(installment.amount.abs())} • '
                  '${TransactionStrings.installmentLocked}',
      ),
      trailing: OutlinedButton.icon(
        onPressed: editable ? onTap : null,
        icon: Icon(
          editable ? Icons.edit_calendar_outlined : Icons.lock_outline,
          size: 18,
        ),
        label: Text(AppFormatters.date(date)),
      ),
    );
  }
}
