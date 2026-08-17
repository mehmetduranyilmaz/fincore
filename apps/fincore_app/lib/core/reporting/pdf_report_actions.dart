import 'package:fincore_app/core/reporting/financial_pdf_report.dart';
import 'package:flutter/material.dart';

final class PdfReportActions extends StatefulWidget {
  const PdfReportActions({required this.report, super.key});

  final FinancialPdfReport? report;

  @override
  State<PdfReportActions> createState() => _PdfReportActionsState();
}

final class _PdfReportActionsState extends State<PdfReportActions> {
  final _service = FinancialPdfReportService();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.report != null && !_busy;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'PDF Paylaş',
          onPressed: enabled ? () => _run(share: true) : null,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share_outlined),
        ),
        IconButton(
          tooltip: 'Yazdır',
          onPressed: enabled ? () => _run(share: false) : null,
          icon: const Icon(Icons.print_outlined),
        ),
      ],
    );
  }

  Future<void> _run({required bool share}) async {
    final report = widget.report;
    if (report == null || _busy) return;
    setState(() => _busy = true);
    try {
      if (share) {
        await _service.share(report);
      } else {
        await _service.printReport(report);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF hazırlanamadı. Lütfen tekrar deneyin.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
