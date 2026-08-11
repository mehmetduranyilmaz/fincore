import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_payment_calendar.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_payment_calendar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class CreditCardPaymentCalendarPage extends ConsumerWidget {
  const CreditCardPaymentCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendar = ref.watch(creditCardPaymentCalendarProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(CreditCardStrings.paymentCalendar)),
      body: calendar.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) =>
            Center(child: Text(CreditCardStrings.paymentCalendarUnableToLoad)),
        data: (value) => value.isEmpty
            ? const AppEmptyState(
                icon: Icons.event_available_outlined,
                title: CreditCardStrings.noScheduledPayments,
                description: CreditCardStrings.noScheduledPaymentsDescription,
              )
            : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: value.years.length + 1,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const _CalendarExplanation();
                        }
                        return _PaymentYearCard(year: value.years[index - 1]);
                      },
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

final class _CalendarExplanation extends StatelessWidget {
  const _CalendarExplanation();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.calendar_view_month_outlined, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          const Expanded(child: Text(CreditCardStrings.paymentCalendarHint)),
        ],
      ),
    );
  }
}

final class _PaymentYearCard extends StatelessWidget {
  const _PaymentYearCard({required this.year});

  final CreditCardPaymentYear year;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            year.year.toString(),
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final month in year.months) ...[
            _PaymentMonthRow(month: month),
            const Divider(height: AppSpacing.md),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      CreditCardStrings.yearTotal,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _CurrencyTotals(
                    totals: year.totalsByCurrency,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _PaymentMonthRow extends StatelessWidget {
  const _PaymentMonthRow({required this.month});

  final CreditCardPaymentMonth month;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month.periodLabel,
                  key: Key('payment_month_${month.periodLabel}'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  CreditCardStrings.scheduledTransactionCount(
                    month.transactionCount,
                  ),
                ),
              ],
            ),
          ),
          _CurrencyTotals(totals: month.totalsByCurrency),
        ],
      ),
    );
  }
}

final class _CurrencyTotals extends StatelessWidget {
  const _CurrencyTotals({required this.totals, this.style});

  final Map<String, double> totals;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final entry in totals.entries)
          Text(
            AppFormatters.currency(entry.value, currencyCode: entry.key),
            style:
                style ??
                Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}
