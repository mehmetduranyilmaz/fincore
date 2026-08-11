import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:flutter/material.dart';

final class TransactionDateField extends StatelessWidget {
  const TransactionDateField({
    required this.value,
    required this.onTap,
    super.key,
  });

  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_outlined),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text('${TransactionStrings.date}: ${AppFormatters.date(value)}'),
      ),
    );
  }
}
