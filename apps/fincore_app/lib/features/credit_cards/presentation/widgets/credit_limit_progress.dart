import 'package:flutter/material.dart';

final class CreditLimitProgress extends StatelessWidget {
  const CreditLimitProgress({
    required this.creditLimit,
    required this.currentDebt,
    super.key,
  });

  final double creditLimit;
  final double currentDebt;

  @override
  Widget build(BuildContext context) {
    final utilization = creditLimit <= 0
        ? 0.0
        : (currentDebt / creditLimit).clamp(0.0, 1.0);

    return LinearProgressIndicator(
      value: utilization,
      minHeight: 6,
      borderRadius: const BorderRadius.all(Radius.circular(3)),
    );
  }
}
