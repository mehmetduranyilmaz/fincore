import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_account_filter.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_date_range_filter.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_search_bar.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_type_filters.dart';
import 'package:flutter/material.dart';

final class TransactionFilters extends StatelessWidget {
  const TransactionFilters({required this.accounts, super.key});

  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TransactionSearchBar(),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const TransactionTypeFilters(),
            const TransactionDateRangeFilter(),
            TransactionAccountFilter(accounts: accounts),
          ],
        ),
      ],
    );
  }
}
