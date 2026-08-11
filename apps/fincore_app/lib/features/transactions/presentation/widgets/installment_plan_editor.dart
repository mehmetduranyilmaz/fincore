import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/transactions/domain/usecases/installment_calculator.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:flutter/material.dart';

final class InstallmentPlanEditor extends StatefulWidget {
  const InstallmentPlanEditor({
    required this.totalAmount,
    required this.initialCount,
    required this.onChanged,
    this.minimumCount = 1,
    this.enabled = true,
    super.key,
  });

  final double totalAmount;
  final int initialCount;
  final ValueChanged<List<double>> onChanged;
  final int minimumCount;
  final bool enabled;

  @override
  State<InstallmentPlanEditor> createState() => _InstallmentPlanEditorState();
}

final class _InstallmentPlanEditorState extends State<InstallmentPlanEditor> {
  late int _count;
  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount.clamp(widget.minimumCount, 36);
    _replaceAmounts(_defaultAmounts());
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  @override
  void didUpdateWidget(InstallmentPlanEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (InstallmentCalculator.toCents(oldWidget.totalAmount) !=
        InstallmentCalculator.toCents(widget.totalAmount)) {
      _replaceAmounts(_defaultAmounts());
      WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _count,
          decoration: const InputDecoration(
            labelText: TransactionStrings.installmentCount,
          ),
          items: [
            for (
              var count = widget.minimumCount;
              count <= InstallmentCalculator.maximumCount;
              count++
            )
              DropdownMenuItem(
                value: count,
                child: Text(
                  count == 1
                      ? TransactionStrings.singlePayment
                      : '$count ${TransactionStrings.installment}',
                ),
              ),
          ],
          onChanged: widget.enabled
              ? (value) {
                  if (value == null || value == _count) {
                    return;
                  }
                  setState(() {
                    _count = value;
                    _replaceAmounts(_defaultAmounts());
                  });
                  _notify();
                }
              : null,
        ),
        if (_count > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            TransactionStrings.installmentAmounts,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (index, controller) in _controllers.indexed) ...[
            AppTextField(
              controller: controller,
              enabled: widget.enabled,
              label:
                  '${index + 1}. ${TransactionStrings.installment.toLowerCase()}',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [TurkishDecimalInputFormatter()],
              validator: (value) {
                final amount = AppFormatters.tryParseDecimal(value ?? '');
                if (amount == null || !amount.isFinite || amount <= 0) {
                  return TransactionStrings.invalidAmount;
                }
                return null;
              },
              onChanged: (_) => _notify(),
            ),
            if (index < _controllers.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
          _TotalStatus(
            totalAmount: widget.totalAmount,
            currentAmount: _currentTotal,
          ),
        ],
      ],
    );
  }

  List<double> _defaultAmounts() {
    if (_count == 1) {
      return [widget.totalAmount];
    }
    if (InstallmentCalculator.toCents(widget.totalAmount) < _count) {
      return List.filled(_count, 0);
    }
    return InstallmentCalculator.splitEvenly(widget.totalAmount, _count);
  }

  void _replaceAmounts(List<double> amounts) {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers = [
      for (final amount in amounts)
        TextEditingController(text: AppFormatters.decimal(amount)),
    ];
  }

  List<double>? get _amounts {
    final values = <double>[];
    for (final controller in _controllers) {
      final value = AppFormatters.tryParseDecimal(controller.text);
      if (value == null) {
        return null;
      }
      values.add(value);
    }
    return values;
  }

  double get _currentTotal {
    return _amounts?.fold<double>(0, (sum, value) => sum + value) ?? 0;
  }

  void _notify() {
    final values = _amounts;
    widget.onChanged(values == null ? const [] : List.unmodifiable(values));
  }
}

final class _TotalStatus extends StatelessWidget {
  const _TotalStatus({required this.totalAmount, required this.currentAmount});

  final double totalAmount;
  final double currentAmount;

  @override
  Widget build(BuildContext context) {
    final isValid =
        InstallmentCalculator.toCents(totalAmount) ==
        InstallmentCalculator.toCents(currentAmount);
    final color = isValid
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Text(
      '${AppFormatters.currency(currentAmount)} / '
      '${AppFormatters.currency(totalAmount)}'
      '${isValid ? '' : ' • ${TransactionStrings.installmentTotalMismatch}'}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
    );
  }
}
