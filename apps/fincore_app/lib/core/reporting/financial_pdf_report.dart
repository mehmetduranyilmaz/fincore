import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum FinancialReportAlignment { left, center, right }

final class FinancialReportColumn {
  const FinancialReportColumn({
    required this.label,
    this.flex = 1,
    this.alignment = FinancialReportAlignment.left,
  });

  final String label;
  final double flex;
  final FinancialReportAlignment alignment;
}

final class FinancialReportMetric {
  const FinancialReportMetric({required this.label, required this.value});

  final String label;
  final String value;
}

final class FinancialPdfReport {
  const FinancialPdfReport({
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.rows,
    this.metrics = const [],
    this.note,
    this.landscape = true,
  });

  final String title;
  final String subtitle;
  final List<FinancialReportColumn> columns;
  final List<List<String>> rows;
  final List<FinancialReportMetric> metrics;
  final String? note;
  final bool landscape;
}

final class FinancialPdfReportBuilder {
  const FinancialPdfReportBuilder();

  static const _regularFontAsset = 'assets/fonts/Lato-Regular.ttf';
  static const _boldFontAsset = 'assets/fonts/Lato-Bold.ttf';

  Future<Uint8List> build(FinancialPdfReport report) async {
    final fontData = await rootBundle.load(_regularFontAsset);
    final boldFontData = await rootBundle.load(_boldFontAsset);
    return await buildWithFonts(
      report,
      regularFont: fontData.buffer.asUint8List(),
      boldFont: boldFontData.buffer.asUint8List(),
    );
  }

  Future<Uint8List> buildWithFonts(
    FinancialPdfReport report, {
    required Uint8List regularFont,
    required Uint8List boldFont,
  }) {
    final regular = pw.Font.ttf(regularFont.buffer.asByteData());
    final bold = pw.Font.ttf(boldFont.buffer.asByteData());
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      title: report.title,
      author: 'Hesabım',
      creator: 'Hesabım Finans Yönetimi',
    );
    final pageFormat = report.landscape
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;
    final generatedAt = DateTime.now();
    final rowChunks = _chunkRows(report.rows, report.landscape ? 12 : 18);

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
        header: (context) => _buildHeader(report, generatedAt, bold),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          if (report.metrics.isNotEmpty) ...[
            _buildMetrics(report.metrics),
            pw.SizedBox(height: 16),
          ],
          for (var index = 0; index < rowChunks.length; index++) ...[
            _buildTable(report, rowChunks[index]),
            if (index < rowChunks.length - 1) pw.NewPage(),
          ],
          if (report.note case final note?) ...[
            pw.SizedBox(height: 14),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF1F5F9),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                note,
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColor.fromInt(0xFF475569),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _buildHeader(
    FinancialPdfReport report,
    DateTime generatedAt,
    pw.Font bold,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF162A4A),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 42,
            height: 42,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF2DD4BF),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              '₺',
              style: pw.TextStyle(
                font: bold,
                fontSize: 23,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(width: 13),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  report.title,
                  style: const pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  report.subtitle,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColor.fromInt(0xFFD6E2F1),
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'HESABIM',
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                  color: PdfColor.fromInt(0xFF5EEAD4),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Oluşturma: ${_dateTime(generatedAt)}',
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColor.fromInt(0xFFD6E2F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetrics(List<FinancialReportMetric> metrics) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final metric in metrics)
          pw.Container(
            width: metrics.length <= 3 ? 165 : 135,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border.all(
                color: const PdfColor.fromInt(0xFFD9E2EC),
                width: .7,
              ),
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  metric.label.toUpperCase(),
                  style: const pw.TextStyle(
                    fontSize: 7,
                    letterSpacing: .5,
                    color: PdfColor.fromInt(0xFF64748B),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  metric.value,
                  style: const pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _buildTable(FinancialPdfReport report, List<List<String>> rows) {
    final widths = <int, pw.TableColumnWidth>{
      for (var index = 0; index < report.columns.length; index++)
        index: pw.FlexColumnWidth(report.columns[index].flex),
    };
    final alignments = <int, pw.Alignment>{
      for (var index = 0; index < report.columns.length; index++)
        index: _alignment(report.columns[index].alignment),
    };
    return pw.TableHelper.fromTextArray(
      headers: [for (final column in report.columns) column.label],
      data: rows,
      columnWidths: widths,
      cellAlignments: alignments,
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF27476E),
      ),
      headerStyle: const pw.TextStyle(
        color: PdfColors.white,
        fontSize: 8.5,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(
        fontSize: 8.2,
        color: PdfColor.fromInt(0xFF1E293B),
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      oddRowDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
      ),
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(
          color: PdfColor.fromInt(0xFFE2E8F0),
          width: .5,
        ),
        bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: .7),
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFD9E2EC), width: .6),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Kişisel finans raporu - Hesabım',
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColor.fromInt(0xFF64748B),
            ),
          ),
          pw.Text(
            'Sayfa ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColor.fromInt(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Alignment _alignment(FinancialReportAlignment alignment) {
    return switch (alignment) {
      FinancialReportAlignment.left => pw.Alignment.centerLeft,
      FinancialReportAlignment.center => pw.Alignment.center,
      FinancialReportAlignment.right => pw.Alignment.centerRight,
    };
  }

  static String _dateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  static List<List<List<String>>> _chunkRows(
    List<List<String>> rows,
    int chunkSize,
  ) {
    if (rows.isEmpty) return const [[]];
    return [
      for (var start = 0; start < rows.length; start += chunkSize)
        rows.sublist(start, (start + chunkSize).clamp(0, rows.length)),
    ];
  }
}

final class FinancialPdfReportService {
  FinancialPdfReportService({FinancialPdfReportBuilder? builder})
    : _builder = builder ?? const FinancialPdfReportBuilder();

  final FinancialPdfReportBuilder _builder;

  Future<void> share(FinancialPdfReport report) async {
    final bytes = await _builder.build(report);
    await Printing.sharePdf(
      bytes: bytes,
      filename: _filename(report.title),
      subject: report.title,
    );
  }

  Future<void> printReport(FinancialPdfReport report) async {
    final bytes = await _builder.build(report);
    await Printing.layoutPdf(name: report.title, onLayout: (_) async => bytes);
  }

  static String _filename(String title) {
    final safeTitle = title
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp('[^a-z0-9]+'), '-');
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    return '$safeTitle-$date.pdf';
  }
}
