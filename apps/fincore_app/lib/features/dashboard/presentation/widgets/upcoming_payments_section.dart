import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/dashboard/domain/entities/upcoming_payment.dart';
import 'package:fincore_app/features/dashboard/presentation/constants/dashboard_strings.dart';
import 'package:fincore_app/features/dashboard/presentation/utils/dashboard_formatters.dart';
import 'package:flutter/material.dart';

final class UpcomingPaymentsSection extends StatelessWidget {
  const UpcomingPaymentsSection({required this.payments, super.key});

  final List<UpcomingPayment> payments;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: DashboardStrings.upcomingPayments),
          const SizedBox(height: AppSpacing.md),
          if (payments.isEmpty)
            const AppEmptyState(
              icon: Icons.event_available_outlined,
              title: DashboardStrings.noUpcomingPayments,
              description: DashboardStrings.noUpcomingPaymentsDescription,
            )
          else
            for (final (index, payment) in payments.indexed) ...[
              _UpcomingPaymentTile(payment: payment),
              if (index < payments.length - 1) const Divider(),
            ],
        ],
      ),
    );
  }
}

final class _UpcomingPaymentTile extends StatelessWidget {
  const _UpcomingPaymentTile({required this.payment});

  final UpcomingPayment payment;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today_outlined),
      title: Text(payment.title),
      subtitle: Text(DashboardFormatters.date(payment.dueDate)),
      trailing: Text(
        DashboardFormatters.currency(payment.amount),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
