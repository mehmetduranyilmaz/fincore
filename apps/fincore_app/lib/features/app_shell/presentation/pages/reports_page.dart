import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/categories/presentation/constants/category_strings.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_icon.dart';
import 'package:fincore_app/features/reports/domain/entities/expense_category_report.dart';
import 'package:fincore_app/features/reports/domain/entities/expense_report_period.dart';
import 'package:fincore_app/features/reports/presentation/constants/report_strings.dart';
import 'package:fincore_app/features/reports/presentation/controllers/expense_report_period_controller.dart';
import 'package:fincore_app/features/reports/presentation/providers/expense_category_report_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(expenseReportPeriodControllerProvider);
    final report = ref.watch(expenseCategoryReportProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: ReportStrings.title,
            action: IconButton(
              key: const Key('open_cash_flow'),
              tooltip: 'Nakit Akışı',
              onPressed: () => context.push(AppRoutes.cashFlow),
              icon: const Icon(Icons.account_balance_wallet_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ReportStrings.subtitle,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          _PeriodSelector(period: period),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: report.when(
              loading: () => const AppLoadingView(),
              error: (error, stackTrace) => AppErrorView(
                message: ErrorMapper.map(error),
                retryLabel: ReportStrings.retry,
                onRetry: () => ref.invalidate(expenseCategoryReportProvider),
              ),
              data: (value) => value.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.assessment_outlined,
                      title: ReportStrings.noExpenses,
                      description: ReportStrings.noExpensesDescription,
                    )
                  : _ReportContent(report: value),
            ),
          ),
        ],
      ),
    );
  }
}

final class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector({required this.period});

  final ExpenseReportPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(expenseReportPeriodControllerProvider.notifier);
    return AppCard(
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SegmentedButton<ExpenseReportPeriodType>(
            segments: const [
              ButtonSegment(
                value: ExpenseReportPeriodType.monthly,
                label: Text(ReportStrings.monthly),
                icon: Icon(Icons.calendar_view_month_outlined),
              ),
              ButtonSegment(
                value: ExpenseReportPeriodType.yearly,
                label: Text(ReportStrings.yearly),
                icon: Icon(Icons.calendar_today_outlined),
              ),
            ],
            selected: {period.type},
            onSelectionChanged: (selection) {
              controller.changeType(selection.single);
            },
          ),
          Wrap(
            spacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: ReportStrings.previousPeriod,
                onPressed: controller.previous,
                icon: const Icon(Icons.chevron_left),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 128),
                child: Text(
                  period.type == ExpenseReportPeriodType.monthly
                      ? ReportStrings.monthYear(period.anchor)
                      : period.anchor.year.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: ReportStrings.nextPeriod,
                onPressed: controller.next,
                icon: const Icon(Icons.chevron_right),
              ),
              TextButton(
                onPressed: controller.current,
                child: const Text(ReportStrings.currentPeriod),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.report});

  final ExpenseCategoryReport report;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: report.currencies.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xl),
      itemBuilder: (context, index) =>
          _CurrencyReportSection(report: report.currencies[index]),
    );
  }
}

final class _CurrencyReportSection extends StatelessWidget {
  const _CurrencyReportSection({required this.report});

  final CurrencyExpenseReport report;

  @override
  Widget build(BuildContext context) {
    final currencyTitle = report.currencyCode == 'N/A'
        ? ReportStrings.unknownCurrency
        : report.currencyCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(currencyTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        _SummaryMetrics(report: report),
        const SizedBox(height: AppSpacing.lg),
        for (var index = 0; index < report.categories.length; index++) ...[
          _CategoryBreakdownCard(
            category: report.categories[index],
            currencyCode: report.currencyCode,
          ),
          if (index != report.categories.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

final class _SummaryMetrics extends StatelessWidget {
  const _SummaryMetrics({required this.report});

  final CurrencyExpenseReport report;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 800 ? 4 : 2;
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _MetricCard(
              width: width,
              icon: Icons.payments_outlined,
              label: ReportStrings.totalExpense,
              value: _currency(report.totalAmount),
            ),
            _MetricCard(
              width: width,
              icon: Icons.receipt_long_outlined,
              label: ReportStrings.transactionCount,
              value: report.transactionCount.toString(),
            ),
            _MetricCard(
              width: width,
              icon: Icons.calculate_outlined,
              label: ReportStrings.averageExpense,
              value: _currency(report.averageTransactionAmount),
            ),
            _MetricCard(
              width: width,
              icon: Icons.category_outlined,
              label: ReportStrings.categoryCount,
              value: report.categories.length.toString(),
            ),
          ],
        );
      },
    );
  }

  String _currency(double amount) {
    return AppFormatters.currency(amount, currencyCode: report.currencyCode);
  }
}

final class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({
    required this.category,
    required this.currencyCode,
  });

  final CategoryExpenseBreakdown category;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(category.color);
    final percentage = (category.percentage * 100)
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: CategoryIcon(icon: category.icon, color: category.color),
          ),
        ),
        title: Text(
          CategoryStrings.displayName(category.name),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${category.transactionCount} ${ReportStrings.transaction} • %$percentage',
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: category.percentage.clamp(0, 1),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                color: categoryColor,
              ),
            ],
          ),
        ),
        trailing: Text(
          AppFormatters.currency(category.amount, currencyCode: currencyCode),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        children: [
          const Divider(),
          for (final transaction in category.transactions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(transaction.description),
              subtitle: Text(AppFormatters.date(transaction.date)),
              trailing: Text(
                AppFormatters.currency(
                  transaction.amount,
                  currencyCode: currencyCode,
                ),
              ),
              onTap: () => context.push(
                AppRoutes.transactionDetailsLocation(transaction.id),
              ),
            ),
        ],
      ),
    );
  }
}
