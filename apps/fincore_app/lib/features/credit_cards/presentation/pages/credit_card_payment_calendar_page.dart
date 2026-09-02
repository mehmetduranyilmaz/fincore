import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/reporting/pdf_report_actions.dart';
import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_payment_calendar.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_payment_calendar_provider.dart';
import 'package:fincore_app/features/reports/presentation/financial_report_factories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreditCardPaymentCalendarPage extends ConsumerStatefulWidget {
  const CreditCardPaymentCalendarPage({this.referenceDate, super.key});

  final DateTime? referenceDate;

  @override
  ConsumerState<CreditCardPaymentCalendarPage> createState() =>
      _CreditCardPaymentCalendarPageState();
}

final class _CreditCardPaymentCalendarPageState
    extends ConsumerState<CreditCardPaymentCalendarPage> {
  bool _showMonths = true;
  bool _showDetails = true;
  late DateTime _startMonth;
  DateTime? _endMonth;

  @override
  void initState() {
    super.initState();
    final now = widget.referenceDate ?? DateTime.now();
    _startMonth = DateTime(now.year, now.month - 3);
  }

  @override
  Widget build(BuildContext context) {
    final calendar = ref.watch(creditCardPaymentCalendarProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(CreditCardStrings.paymentCalendar),
        actions: [
          IconButton(
            tooltip: 'Tekrarlayan Giderler',
            onPressed: () => context.push(AppRoutes.recurringExpenses),
            icon: const Icon(Icons.event_repeat_outlined),
          ),
          PdfReportActions(
            report: calendar.value?.isEmpty == false
                ? FinancialReportFactories.paymentCalendar(calendar.value!)
                : null,
          ),
        ],
      ),
      body: calendar.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) =>
            Center(child: Text(CreditCardStrings.paymentCalendarUnableToLoad)),
        data: (calendarValue) {
          final value = _filterCalendar(calendarValue);
          return value.isEmpty
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
                        itemCount: value.years.length + 2,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const _CalendarExplanation();
                          }
                          if (index == 1) {
                            return Wrap(
                              alignment: WrapAlignment.end,
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                OutlinedButton.icon(
                                  key: const Key('payment_calendar_date_range'),
                                  onPressed: _selectDateRange,
                                  icon: const Icon(Icons.date_range_outlined),
                                  label: Text(
                                    _endMonth == null
                                        ? '${_monthLabel(_startMonth)} - tüm gelecek'
                                        : '${_monthLabel(_startMonth)} - ${_monthLabel(_endMonth!)}',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  key: const Key(
                                    'payment_calendar_toggle_months',
                                  ),
                                  onPressed: () => setState(() {
                                    if (_showMonths) {
                                      _showMonths = false;
                                      _showDetails = false;
                                    } else {
                                      _showMonths = true;
                                    }
                                  }),
                                  icon: Icon(
                                    _showMonths
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  label: Text(
                                    _showMonths
                                        ? CreditCardStrings.hideMonths
                                        : CreditCardStrings.showMonths,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  key: const Key(
                                    'payment_calendar_toggle_details',
                                  ),
                                  onPressed: !_showMonths
                                      ? null
                                      : () => setState(
                                          () => _showDetails = !_showDetails,
                                        ),
                                  icon: Icon(
                                    _showDetails
                                        ? Icons.list_alt_outlined
                                        : Icons.format_list_bulleted_outlined,
                                  ),
                                  label: Text(
                                    _showDetails
                                        ? CreditCardStrings.hideDetails
                                        : CreditCardStrings.showDetails,
                                  ),
                                ),
                              ],
                            );
                          }
                          return _PaymentYearCard(
                            year: value.years[index - 2],
                            showMonths: _showMonths,
                            showDetails: _showDetails,
                          );
                        },
                      ),
                    ),
                  ),
                );
        },
      ),
    );
  }

  CreditCardPaymentCalendar _filterCalendar(
    CreditCardPaymentCalendar calendar,
  ) {
    final years = <CreditCardPaymentYear>[];
    for (final year in calendar.years) {
      final months = year.months.where((month) {
        final date = DateTime(month.year, month.month);
        return !date.isBefore(_startMonth) &&
            (_endMonth == null || !date.isAfter(_endMonth!));
      }).toList();
      if (months.isEmpty) continue;
      final totals = <String, double>{};
      for (final month in months) {
        for (final entry in month.totalsByCurrency.entries) {
          totals.update(
            entry.key,
            (value) => value + entry.value,
            ifAbsent: () => entry.value,
          );
        }
      }
      years.add(
        CreditCardPaymentYear(
          year: year.year,
          months: months,
          totalsByCurrency: totals,
        ),
      );
    }
    return CreditCardPaymentCalendar(years);
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20, 12, 31),
      initialDateRange: DateTimeRange(
        start: _startMonth,
        end: _endMonth ?? DateTime(now.year + 1, now.month),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _startMonth = DateTime(selected.start.year, selected.start.month);
      _endMonth = DateTime(selected.end.year, selected.end.month);
    });
  }

  static String _monthLabel(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
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
  const _PaymentYearCard({
    required this.year,
    required this.showMonths,
    required this.showDetails,
  });

  final CreditCardPaymentYear year;
  final bool showMonths;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showMonths) ...[
            Text(
              year.year.toString(),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final month in year.months) ...[
              _PaymentMonthRow(month: month, showDetails: showDetails),
              const Divider(height: AppSpacing.md),
            ],
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
                      CreditCardStrings.yearTotal(year.year),
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
  const _PaymentMonthRow({required this.month, required this.showDetails});

  final CreditCardPaymentMonth month;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percentage = (month.completionRatio * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                      month.periodLabel,
                      key: Key('payment_month_${month.periodLabel}'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      CreditCardStrings.scheduledTransactionCount(
                        confirmedCount: month.confirmedTransactionCount,
                        plannedCount: month.plannedExpenseCount,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (month.isPaid) ...[
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: colors.tertiary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Text(
                          '%$percentage tamamlandı',
                          key: Key('payment_progress_${month.periodLabel}'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: month.isPaid
                                    ? colors.tertiary
                                    : colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    LinearProgressIndicator(value: month.completionRatio),
                    const SizedBox(height: AppSpacing.xs),
                    _CurrencyTotals(
                      totals: month.remainingByCurrency,
                      prefix: 'Kalan: ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _CurrencyTotals(totals: month.totalsByCurrency),
            ],
          ),
          if (showDetails && month.details.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final detail in month.details) ...[
              _PaymentDetailRow(detail: detail),
              if (detail != month.details.last)
                const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ],
      ),
    );
  }
}

final class _PaymentDetailRow extends StatelessWidget {
  const _PaymentDetailRow({required this.detail});

  final CreditCardPaymentDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(_detailIcon(detail.kind), size: 20, color: colors.primary),
            if (detail.isPaid) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.check_circle, size: 20, color: colors.tertiary),
            ],
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.label,
                    key: Key(
                      'payment_detail_${detail.kind.name}_${detail.sourceId}',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    CreditCardStrings.scheduledTransactionCount(
                      confirmedCount: detail.confirmedTransactionCount,
                      plannedCount: detail.plannedExpenseCount,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _CurrencyTotals(totals: detail.totalsByCurrency),
          ],
        ),
      ),
    );
  }

  static IconData _detailIcon(CreditCardPaymentDetailKind kind) {
    return switch (kind) {
      CreditCardPaymentDetailKind.creditCard => Icons.credit_card_outlined,
      CreditCardPaymentDetailKind.customer => Icons.person_outline,
      CreditCardPaymentDetailKind.account =>
        Icons.account_balance_wallet_outlined,
    };
  }
}

final class _CurrencyTotals extends StatelessWidget {
  const _CurrencyTotals({required this.totals, this.style, this.prefix = ''});

  final Map<String, double> totals;
  final TextStyle? style;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final entry in totals.entries)
          Text(
            '$prefix${AppFormatters.currency(entry.value, currencyCode: entry.key)}',
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
