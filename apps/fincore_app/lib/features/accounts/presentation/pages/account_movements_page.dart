import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/reporting/pdf_report_actions.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/accounts/presentation/providers/account_balance_provider.dart';
import 'package:fincore_app/features/accounts/presentation/providers/account_movements_provider.dart';
import 'package:fincore_app/features/reports/presentation/financial_report_factories.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class AccountMovementsPage extends ConsumerStatefulWidget {
  const AccountMovementsPage({required this.accountId, super.key});

  final String accountId;

  @override
  ConsumerState<AccountMovementsPage> createState() =>
      _AccountMovementsPageState();
}

final class _AccountMovementsPageState
    extends ConsumerState<AccountMovementsPage> {
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month - 3, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider(widget.accountId));
    final query = (
      accountId: widget.accountId,
      startDate: _range.start,
      endDate: _range.end,
    );
    final movements = ref.watch(accountMovementsProvider(query));
    return Scaffold(
      appBar: AppBar(
        title: Text('${account.value?.name ?? 'Hesap'} • Hareketler'),
        actions: [
          PdfReportActions(
            report: account.value != null && movements.value != null
                ? FinancialReportFactories.accountMovements(
                    account: account.value!,
                    movements: movements.value!,
                    startDate: _range.start,
                    endDate: _range.end,
                  )
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                key: const Key('account_movements_date_range'),
                onPressed: _selectRange,
                icon: const Icon(Icons.date_range_outlined),
                label: Text(
                  '${AppFormatters.date(_range.start)} - '
                  '${AppFormatters.date(_range.end)}',
                ),
              ),
            ),
          ),
          Expanded(
            child: movements.when(
              loading: () => const AppLoadingView(),
              error: (error, stackTrace) => AppErrorView(
                message: 'Hesap hareketleri yüklenemedi.',
                retryLabel: 'Tekrar dene',
                onRetry: () => ref.invalidate(accountMovementsProvider(query)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Bu aralıkta hareket yok',
                    description: 'Başka bir tarih aralığı seçebilirsiniz.',
                  );
                }
                final currency = account.value?.currencyCode ?? 'TRY';
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final transaction = item.transaction;
                    final delta = switch (transaction.transactionType) {
                      TransactionType.income => transaction.amount.abs(),
                      TransactionType.expense => -transaction.amount.abs(),
                      TransactionType.transfer => transaction.amount,
                    };
                    return AppCard(
                      onTap: () => context.push(
                        AppRoutes.transactionDetailsLocation(transaction.id),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Icon(
                            delta >= 0 ? Icons.call_received : Icons.call_made,
                          ),
                        ),
                        title: Text(transaction.merchant),
                        subtitle: Text(
                          '${AppFormatters.date(transaction.transactionDate)} • '
                          '${_typeLabel(transaction.transactionType)} • '
                          '${delta >= 0 ? 'Giriş' : 'Çıkış'}\n'
                          'İşlem sonrası bakiye: '
                          '${AppFormatters.currency(item.balanceAfterMovement, currencyCode: currency)}',
                        ),
                        trailing: Text(
                          '${delta >= 0 ? '+' : '-'}${AppFormatters.currency(delta.abs(), currencyCode: currency)}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDateRange: _range,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _range = DateTimeRange(
        start: DateTime(
          selected.start.year,
          selected.start.month,
          selected.start.day,
        ),
        end: DateTime(
          selected.end.year,
          selected.end.month,
          selected.end.day,
          23,
          59,
          59,
          999,
        ),
      );
    });
  }

  static String _typeLabel(TransactionType type) => switch (type) {
    TransactionType.income => 'Gelir',
    TransactionType.expense => 'Gider',
    TransactionType.transfer => 'Transfer',
  };
}
