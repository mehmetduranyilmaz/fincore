import 'dart:async';

import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/create_credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/create_credit_card_statement_controller.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreateCreditCardStatementPage extends ConsumerStatefulWidget {
  const CreateCreditCardStatementPage({required this.creditCardId, super.key});

  final String creditCardId;

  @override
  ConsumerState<CreateCreditCardStatementPage> createState() =>
      _CreateCreditCardStatementPageState();
}

final class _CreateCreditCardStatementPageState
    extends ConsumerState<CreateCreditCardStatementPage> {
  late DateTime _statementDate;
  late DateTime _dueDate;
  CreditCard? _creditCard;
  List<Transaction> _candidates = const [];
  Set<String> _selectedIds = {};
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _statementDate = DateTime(now.year, now.month, now.day);
    _dueDate = _statementDate.add(const Duration(days: 10));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createCreditCardStatementControllerProvider.notifier).reset();
      unawaited(_load(initialLoad: true));
    });
  }

  Future<void> _load({bool initialLoad = false}) async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final card =
          _creditCard ??
          await ref
              .read(creditCardCommandRepositoryProvider)
              .getById(widget.creditCardId);
      if (card == null) throw StateError('Credit card not found.');
      if (initialLoad) {
        _dueDate = _suggestDueDate(_statementDate, card.dueDay);
      }
      final candidates = await ref
          .read(getCreditCardStatementCandidatesProvider)
          .execute(
            creditCardId: widget.creditCardId,
            statementDate: _statementDate,
          );
      final statementDayStart = DateTime(
        _statementDate.year,
        _statementDate.month,
        _statementDate.day,
      );
      if (!mounted) return;
      setState(() {
        _creditCard = card;
        _candidates = candidates;
        // The exact cut-off day is deliberately left for user review.
        _selectedIds = {
          for (final item in candidates)
            if (item.transactionDate.isBefore(statementDayStart)) item.id,
        };
        _isLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = CreditCardStrings.statementsUnableToLoad;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final command = ref.watch(createCreditCardStatementControllerProvider);
    final card = _creditCard;
    return Scaffold(
      appBar: AppBar(title: const Text(CreditCardStrings.createStatement)),
      body: _isLoading
          ? const AppLoadingView()
          : _loadError != null || card == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError ?? CreditCardStrings.cardNotFound),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: _load,
                    child: const Text(CreditCardStrings.retry),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${card.bankName} ${card.cardName} ••••${card.lastFourDigits}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  _dateButton(
                                    key: const Key('statement_date_button'),
                                    label: CreditCardStrings.statementDate,
                                    value: _statementDate,
                                    onPressed: _selectStatementDate,
                                  ),
                                  _dateButton(
                                    key: const Key('statement_due_date_button'),
                                    label: CreditCardStrings.statementDueDate,
                                    value: _dueDate,
                                    onPressed: _selectDueDate,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                CreditCardStrings.statementSelectionHint,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${CreditCardStrings.selectedTransactions}: '
                                '${_selectedIds.length}/${_candidates.length}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            TextButton.icon(
                              key: const Key('toggle_all_statement_lines'),
                              onPressed: _candidates.isEmpty
                                  ? null
                                  : _toggleAll,
                              icon: Icon(
                                _selectedIds.length == _candidates.length
                                    ? Icons.deselect
                                    : Icons.select_all,
                              ),
                              label: Text(
                                _selectedIds.length == _candidates.length
                                    ? CreditCardStrings.clearSelection
                                    : CreditCardStrings.selectAll,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Expanded(
                          child: _candidates.isEmpty
                              ? const AppEmptyState(
                                  icon: Icons.check_circle_outline,
                                  title:
                                      CreditCardStrings.noStatementCandidates,
                                  description: CreditCardStrings
                                      .noStatementCandidatesDescription,
                                )
                              : ListView.separated(
                                  key: const Key('statement_candidate_list'),
                                  itemCount: _candidates.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: AppSpacing.sm),
                                  itemBuilder: (context, index) =>
                                      _candidateTile(_candidates[index], card),
                                ),
                        ),
                        if (command.errorMessage case final message?) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      CreditCardStrings.statementTotal,
                                    ),
                                    Text(
                                      AppFormatters.currency(
                                        _selectedTotal,
                                        currencyCode: card.currencyCode,
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ],
                                ),
                              ),
                              AppButton(
                                label: CreditCardStrings.saveStatement,
                                isLoading:
                                    command.status ==
                                    CreateCreditCardStatementStatus.loading,
                                onPressed: _selectedIds.isEmpty ? null : _save,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _dateButton({
    required Key key,
    required String label,
    required DateTime value,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      key: key,
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text('$label: ${AppFormatters.date(value)}'),
    );
  }

  Widget _candidateTile(Transaction transaction, CreditCard card) {
    final selected = _selectedIds.contains(transaction.id);
    final isCutoffDay = DateUtils.isSameDay(
      transaction.transactionDate,
      _statementDate,
    );
    final amount = transaction.transactionType == TransactionType.expense
        ? transaction.amount.abs()
        : -transaction.amount.abs();
    final installment = transaction.isInstallment
        ? ' • ${transaction.installmentNumber}/${transaction.installmentCount} taksit'
        : '';
    return AppCard(
      padding: EdgeInsets.zero,
      child: CheckboxListTile(
        key: Key('statement_line_${transaction.id}'),
        value: selected,
        onChanged: (_) => _toggle(transaction.id),
        title: Text(transaction.merchant),
        subtitle: Text(
          '${AppFormatters.date(transaction.transactionDate)}$installment'
          '${isCutoffDay ? ' • Kesim günü' : ''}',
        ),
        secondary: Text(
          AppFormatters.currency(amount, currencyCode: card.currencyCode),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  double get _selectedTotal {
    return _candidates
        .where((item) => _selectedIds.contains(item.id))
        .fold(
          0,
          (total, item) =>
              total +
              (item.transactionType == TransactionType.expense
                  ? item.amount.abs()
                  : -item.amount.abs()),
        );
  }

  void _toggle(String transactionId) {
    setState(() {
      if (!_selectedIds.add(transactionId)) {
        _selectedIds.remove(transactionId);
      }
    });
  }

  void _toggleAll() {
    setState(() {
      _selectedIds = _selectedIds.length == _candidates.length
          ? {}
          : {for (final item in _candidates) item.id};
    });
  }

  Future<void> _selectStatementDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _statementDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (selected == null || !mounted) return;
    _statementDate = selected;
    _dueDate = _suggestDueDate(selected, _creditCard!.dueDay);
    await _load();
  }

  Future<void> _selectDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: _statementDate.add(const Duration(days: 1)),
      lastDate: _statementDate.add(const Duration(days: 90)),
    );
    if (selected != null && mounted) setState(() => _dueDate = selected);
  }

  Future<void> _save() async {
    final success = await ref
        .read(createCreditCardStatementControllerProvider.notifier)
        .create(
          CreateCreditCardStatementInput(
            creditCardId: widget.creditCardId,
            statementDate: _statementDate,
            dueDate: _dueDate,
            transactionIds: Set.unmodifiable(_selectedIds),
          ),
        );
    if (success && mounted) context.pop();
  }

  static DateTime _suggestDueDate(DateTime statementDate, int dueDay) {
    final thisMonthLastDay = DateTime(
      statementDate.year,
      statementDate.month + 1,
      0,
    ).day;
    var candidate = DateTime(
      statementDate.year,
      statementDate.month,
      dueDay.clamp(1, thisMonthLastDay),
    );
    if (!candidate.isAfter(statementDate)) {
      final nextMonthLastDay = DateTime(
        statementDate.year,
        statementDate.month + 2,
        0,
      ).day;
      candidate = DateTime(
        statementDate.year,
        statementDate.month + 1,
        dueDay.clamp(1, nextMonthLastDay),
      );
    }
    return candidate;
  }
}
