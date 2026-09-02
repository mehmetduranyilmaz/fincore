import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/reports/domain/entities/cash_flow_report.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef CashFlowQuery = ({DateTime startDate, DateTime endDate});

final cashFlowReportProvider =
    FutureProvider.family<CashFlowReport, CashFlowQuery>(
      (ref, query) => ref
          .watch(calculateCashFlowReportProvider)
          .execute(startDate: query.startDate, endDate: query.endDate),
    );
