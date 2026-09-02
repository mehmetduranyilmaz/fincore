import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/reports/domain/entities/cash_flow_report.dart';
import 'package:fincore_app/features/reports/presentation/providers/cash_flow_report_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CashFlowPage extends ConsumerStatefulWidget {
  const CashFlowPage({super.key});

  @override
  ConsumerState<CashFlowPage> createState() => _CashFlowPageState();
}

final class _CashFlowPageState extends ConsumerState<CashFlowPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final query = (
      startDate: _month,
      endDate: DateTime(
        _month.year,
        _month.month + 1,
      ).subtract(const Duration(milliseconds: 1)),
    );
    final report = ref.watch(cashFlowReportProvider(query));
    return Scaffold(
      appBar: AppBar(title: const Text('Nakit Akışı')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month + 1),
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: report.when(
              loading: () => const AppLoadingView(),
              error: (_, _) =>
                  const Center(child: Text('Nakit akışı yüklenemedi.')),
              data: (value) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  _TotalsCard(report: value),
                  const SizedBox(height: AppSpacing.lg),
                  _EntriesSection(
                    title: 'Nakit girişleri',
                    entries: value.inflows,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _EntriesSection(
                    title: 'Nakit çıkışları',
                    entries: value.outflows,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Mevcut para',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      children: [
                        _TotalsRow(label: 'Kasa', values: value.cashBalances),
                        _TotalsRow(
                          label: 'Bankalar',
                          values: value.bankBalances,
                        ),
                        _TotalsRow(
                          label: 'Toplam likit bakiye',
                          values: value.liquidBalances,
                        ),
                        const Divider(),
                        for (final account in value.accountBalances)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(account.accountName),
                            trailing: Text(
                              AppFormatters.currency(
                                account.balance,
                                currencyCode: account.currencyCode,
                              ),
                            ),
                          ),
                      ],
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

final class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.report});
  final CashFlowReport report;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        _TotalsRow(label: 'Toplam giriş', values: report.totalInflows),
        _TotalsRow(label: 'Toplam çıkış', values: report.totalOutflows),
        _TotalsRow(label: 'Net nakit akışı', values: report.netByCurrency),
      ],
    ),
  );
}

final class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.label, required this.values});
  final String label;
  final Map<String, double> values;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final entry in values.entries)
          Text(AppFormatters.currency(entry.value, currencyCode: entry.key)),
      ],
    ),
  );
}

final class _EntriesSection extends StatelessWidget {
  const _EntriesSection({required this.title, required this.entries});
  final String title;
  final List<CashFlowEntry> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      if (entries.isEmpty)
        const AppCard(child: Text('Bu dönemde hareket yok.'))
      else
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              onTap: () => context.push(
                AppRoutes.transactionDetailsLocation(entry.transactionId),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.description),
                subtitle: Text(entry.accountName),
                trailing: Text(
                  AppFormatters.currency(
                    entry.amount,
                    currencyCode: entry.currencyCode,
                  ),
                ),
              ),
            ),
          ),
    ],
  );
}
