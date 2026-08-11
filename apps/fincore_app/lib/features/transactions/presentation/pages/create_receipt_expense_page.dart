import 'dart:async';

import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/presentation/controllers/categories_controller.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_selector.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/credit_cards_controller.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_receipt_expense_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/receipt_scan_draft.dart';
import 'package:fincore_app/features/transactions/domain/services/receipt_scanner.dart';
import 'package:fincore_app/features/transactions/domain/usecases/installment_calculator.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/create_receipt_expense_controller.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/receipt_scan_controller.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_date_field.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_source_selector.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/installment_plan_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreateReceiptExpensePage extends ConsumerStatefulWidget {
  const CreateReceiptExpensePage({super.key});

  @override
  ConsumerState<CreateReceiptExpensePage> createState() =>
      _CreateReceiptExpensePageState();
}

final class _CreateReceiptExpensePageState
    extends ConsumerState<CreateReceiptExpensePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(receiptScanControllerProvider.notifier).reset();
        ref.read(createReceiptExpenseControllerProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiptScanControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(TransactionStrings.scanReceiptExpense)),
      body: switch (state.status) {
        ReceiptScanStatus.initial => _ReceiptSourceChooser(
          onCamera: () => _scan(ReceiptImageSource.camera),
          onGallery: () => _scan(ReceiptImageSource.gallery),
        ),
        ReceiptScanStatus.scanning => const AppLoadingView(),
        ReceiptScanStatus.failure => AppErrorView(
          message: state.errorMessage ?? TransactionStrings.unableToLoad,
          retryLabel: TransactionStrings.scanAnotherReceipt,
          onRetry: ref.read(receiptScanControllerProvider.notifier).reset,
        ),
        ReceiptScanStatus.review => _ReceiptReviewForm(
          key: ValueKey(state.draft!.rawText.hashCode),
          draft: state.draft!,
          onScanAgain: ref.read(receiptScanControllerProvider.notifier).reset,
        ),
      },
    );
  }

  Future<void> _scan(ReceiptImageSource source) {
    return ref.read(receiptScanControllerProvider.notifier).scan(source);
  }
}

final class _ReceiptSourceChooser extends StatelessWidget {
  const _ReceiptSourceChooser({
    required this.onCamera,
    required this.onGallery,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
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
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    TransactionStrings.scanReceiptExpense,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    TransactionStrings.receiptReviewDescription,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: TransactionStrings.scanWithCamera,
                    icon: Icons.camera_alt_outlined,
                    onPressed: onCamera,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text(TransactionStrings.selectFromGallery),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ReceiptReviewForm extends ConsumerStatefulWidget {
  const _ReceiptReviewForm({
    required this.draft,
    required this.onScanAgain,
    super.key,
  });

  final ReceiptScanDraft draft;
  final VoidCallback onScanAgain;

  @override
  ConsumerState<_ReceiptReviewForm> createState() => _ReceiptReviewFormState();
}

final class _ReceiptReviewFormState extends ConsumerState<_ReceiptReviewForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late DateTime _transactionDate;
  late double _totalAmount;
  late String? _categoryId;
  ExpenseSourceSelection? _source;
  List<double> _installmentAmounts = const [];
  bool _didAttemptCardMatch = false;
  String? _planError;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _totalAmount = draft.totalAmount ?? 0;
    _amountController = TextEditingController(
      text: draft.totalAmount == null
          ? null
          : AppFormatters.decimal(draft.totalAmount!),
    );
    _descriptionController = TextEditingController(text: draft.description);
    final date = draft.transactionDate ?? DateTime.now();
    _transactionDate = DateTime(date.year, date.month, date.day);
    _categoryId = draft.suggestedCategoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSources();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createReceiptExpenseControllerProvider);
    final cardsState = ref.watch(creditCardsControllerProvider);
    final categories = ref.watch(
      categoriesControllerProvider.select((state) => state.categories),
    );
    _scheduleCardMatch(cardsState.creditCards);

    ref.listen<CreateReceiptExpenseState>(
      createReceiptExpenseControllerProvider,
      (previous, next) {
        if (next.status == CreateReceiptExpenseStatus.success &&
            context.mounted) {
          context.pop();
        }
      },
    );

    final isLoading = createState.status == CreateReceiptExpenseStatus.loading;
    final initialCount = (widget.draft.installmentCount ?? 1).clamp(1, 36);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      TransactionStrings.receiptReview,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(TransactionStrings.receiptReviewDescription),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _amountController,
                      label: TransactionStrings.originalAmount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: const [TurkishDecimalInputFormatter()],
                      validator: (value) {
                        final amount = AppFormatters.tryParseDecimal(
                          value ?? '',
                        );
                        return amount != null && amount.isFinite && amount > 0
                            ? null
                            : TransactionStrings.invalidAmount;
                      },
                      onChanged: (value) {
                        final amount = AppFormatters.tryParseDecimal(value);
                        if (amount != null && amount > 0) {
                          setState(() {
                            _totalAmount = amount;
                            _planError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _descriptionController,
                      label: TransactionStrings.description,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? TransactionStrings.requiredField
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ExpenseDateField(
                      value: _transactionDate,
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ExpenseSourceSelector(
                      key: ValueKey(
                        '${_source?.accountId ?? _source?.creditCardId ?? ''}-'
                        '${cardsState.creditCards.length}',
                      ),
                      accounts: const [],
                      creditCards: cardsState.creditCards,
                      value: _source,
                      onChanged: (value) => setState(() => _source = value),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _CardMatchMessage(
                      lastFourDigits: widget.draft.lastFourDigits,
                      matched: _source?.creditCardId != null,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: isLoading ? null : _addCreditCard,
                        icon: const Icon(Icons.add_card_outlined),
                        label: const Text(TransactionStrings.addCreditCard),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CategorySelector(
                      key: ValueKey(_categoryId),
                      categories: categories,
                      type: CategoryType.expense,
                      value: _categoryId,
                      onChanged: (value) => setState(() => _categoryId = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InstallmentPlanEditor(
                      totalAmount: _totalAmount,
                      initialCount: initialCount,
                      enabled: !isLoading,
                      onChanged: (values) => _installmentAmounts = values,
                    ),
                    if (_planError case final message?) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (createState.errorMessage case final message?) ...[
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
                            onPressed: isLoading ? null : () => context.pop(),
                            child: const Text(TransactionStrings.cancel),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            label: TransactionStrings.saveExpense,
                            isLoading: isLoading,
                            onPressed: _submit,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: isLoading ? null : widget.onScanAgain,
                      child: const Text(TransactionStrings.scanAnotherReceipt),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _loadSources() {
    final cardStatus = ref.read(creditCardsControllerProvider).status;
    if (cardStatus == CreditCardsStatus.initial ||
        cardStatus == CreditCardsStatus.failure) {
      unawaited(ref.read(creditCardsControllerProvider.notifier).load());
    }
    final categoryStatus = ref.read(categoriesControllerProvider).status;
    if (categoryStatus == CategoriesStatus.initial ||
        categoryStatus == CategoriesStatus.failure) {
      unawaited(ref.read(categoriesControllerProvider.notifier).load());
    }
  }

  void _scheduleCardMatch(List<CreditCard> creditCards) {
    if (_didAttemptCardMatch || creditCards.isEmpty) {
      return;
    }
    _didAttemptCardMatch = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _source != null) {
        return;
      }
      final match = _matchingCard(creditCards);
      if (match != null) {
        setState(() => _source = ExpenseSourceSelection.creditCard(match));
      }
    });
  }

  CreditCard? _matchingCard(List<CreditCard> creditCards) {
    final digits = widget.draft.lastFourDigits;
    if (digits == null) {
      return null;
    }
    for (final card in creditCards) {
      if (!card.isArchived && card.lastFourDigits == digits) {
        return card;
      }
    }
    return null;
  }

  Future<void> _addCreditCard() async {
    await context.push(AppRoutes.createCreditCard);
    if (!mounted) {
      return;
    }
    await ref.read(creditCardsControllerProvider.notifier).load();
    if (!mounted) {
      return;
    }
    final cards = ref.read(creditCardsControllerProvider).creditCards;
    final match = _matchingCard(cards);
    if (match != null) {
      setState(() => _source = ExpenseSourceSelection.creditCard(match));
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _transactionDate.isAfter(now) ? now : _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (date != null && mounted) {
      setState(() => _transactionDate = date);
    }
  }

  Future<void> _submit() async {
    setState(() => _planError = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final totalAmount = AppFormatters.tryParseDecimal(_amountController.text)!;
    final amounts = _installmentAmounts.isEmpty
        ? [totalAmount]
        : _installmentAmounts;
    try {
      if (amounts.length > 1) {
        if (_source?.creditCardId == null) {
          setState(
            () => _planError = TransactionStrings.installmentCardRequired,
          );
          return;
        }
        InstallmentCalculator.validateCustomAmounts(totalAmount, amounts);
      }
    } on ArgumentError {
      setState(() => _planError = TransactionStrings.installmentTotalMismatch);
      return;
    }

    final source = _source!;
    await ref
        .read(createReceiptExpenseControllerProvider.notifier)
        .create(
          CreateReceiptExpenseInput(
            accountId: source.accountId,
            creditCardId: source.creditCardId,
            totalAmount: totalAmount,
            installmentAmounts: amounts,
            description: _descriptionController.text.trim(),
            categoryId: _categoryId,
            transactionDate: _transactionDate,
          ),
        );
  }
}

final class _CardMatchMessage extends StatelessWidget {
  const _CardMatchMessage({
    required this.lastFourDigits,
    required this.matched,
  });

  final String? lastFourDigits;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    if (lastFourDigits == null) {
      return const SizedBox.shrink();
    }
    final color = matched
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Text(
      matched
          ? TransactionStrings.cardMatchFound
          : TransactionStrings.cardMatchNotFound,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
    );
  }
}
