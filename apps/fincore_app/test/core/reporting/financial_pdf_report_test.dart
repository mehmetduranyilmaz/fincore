import 'dart:io';

import 'package:fincore_app/core/reporting/financial_pdf_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a Turkish multi-page financial PDF', () async {
    final regular = await File('assets/fonts/Lato-Regular.ttf').readAsBytes();
    final bold = await File('assets/fonts/Lato-Bold.ttf').readAsBytes();
    final rows = [
      for (var index = 0; index < 90; index++)
        [
          '${(index % 28 + 1).toString().padLeft(2, '0')}.08.2026',
          'Eğitim ve bakım gideri ${index + 1}',
          index.isEven ? 'Gider' : 'K.K. ile Ödm',
          'Araç Bakım',
          '12.345,67 ₺',
        ],
    ];

    final bytes = await const FinancialPdfReportBuilder().buildWithFonts(
      FinancialPdfReport(
        title: 'İşlemler Raporu',
        subtitle: 'Türkçe karakter ve çok sayfalı tablo doğrulaması',
        metrics: const [
          FinancialReportMetric(label: 'Kayıt sayısı', value: '90'),
          FinancialReportMetric(label: 'Toplam gider', value: '123.456,70 ₺'),
        ],
        columns: const [
          FinancialReportColumn(label: 'Tarih'),
          FinancialReportColumn(label: 'Açıklama', flex: 2),
          FinancialReportColumn(label: 'Tür'),
          FinancialReportColumn(label: 'Kategori'),
          FinancialReportColumn(
            label: 'Tutar',
            alignment: FinancialReportAlignment.right,
          ),
        ],
        rows: rows,
        note: 'Ş, Ğ, İ, ı, Ç, Ö ve Ü karakterleri korunmalıdır.',
      ),
      regularFont: regular,
      boldFont: bold,
    );

    expect(bytes.length, greaterThan(10000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('builds a portrait payment calendar PDF', () async {
    final regular = await File('assets/fonts/Lato-Regular.ttf').readAsBytes();
    final bold = await File('assets/fonts/Lato-Bold.ttf').readAsBytes();
    final bytes = await const FinancialPdfReportBuilder().buildWithFonts(
      const FinancialPdfReport(
        title: 'Aylık Ödeme Takvimi',
        subtitle: 'Kredi kartı işlemleri ve planlanan tekrarlayan giderler',
        landscape: false,
        metrics: [
          FinancialReportMetric(label: 'Yıl sayısı', value: '2'),
          FinancialReportMetric(label: 'Ay sayısı', value: '8'),
          FinancialReportMetric(label: 'Planlanan gider', value: '6'),
        ],
        columns: [
          FinancialReportColumn(label: 'Dönem', flex: 1.6),
          FinancialReportColumn(
            label: 'İşlem/Taksit',
            alignment: FinancialReportAlignment.center,
          ),
          FinancialReportColumn(
            label: 'Planlanan',
            alignment: FinancialReportAlignment.center,
          ),
          FinancialReportColumn(
            label: 'Toplam Ödeme',
            flex: 2,
            alignment: FinancialReportAlignment.right,
          ),
        ],
        rows: [
          ['2026-08', '8', '1', '53.976,53 ₺'],
          ['2026-09', '2', '1', '21.768,74 ₺'],
          ['2026-10', '2', '1', '18.954,45 ₺'],
          ['2026-11', '2', '1', '11.326,50 ₺'],
          ['2026-12', '2', '1', '11.326,50 ₺'],
          ['2026 Yılı Toplamı', '-', '-', '117.352,72 ₺'],
          ['2027-01', '1', '1', '2.750,00 ₺'],
          ['2027-02', '1', '1', '2.750,00 ₺'],
          ['2027-03', '1', '1', '2.750,00 ₺'],
          ['2027 Yılı Toplamı', '-', '-', '8.250,00 ₺'],
        ],
        note:
            'Planlanan giderler vadesinden önce gerçek hesap ve kart bakiyelerini etkilemez.',
      ),
      regularFont: regular,
      boldFont: bold,
    );
    expect(bytes.length, greaterThan(10000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
