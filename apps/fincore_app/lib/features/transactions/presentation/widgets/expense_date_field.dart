import 'package:fincore_app/features/transactions/presentation/widgets/transaction_date_field.dart';
import 'package:flutter/material.dart';

final class ExpenseDateField extends StatelessWidget {
  const ExpenseDateField({required this.value, required this.onTap, super.key});

  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TransactionDateField(value: value, onTap: onTap);
  }
}
