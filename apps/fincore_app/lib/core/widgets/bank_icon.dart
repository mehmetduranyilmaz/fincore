import 'package:fincore_app/core/banking/turkish_bank.dart';
import 'package:flutter/material.dart';

final class BankIcon extends StatelessWidget {
  const BankIcon({required this.bank, this.size = 42, super.key});

  final TurkishBank bank;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${bank.name} banka ikonu',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(bank.color),
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.all(size * 0.18),
            child: Text(
              bank.badge,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
