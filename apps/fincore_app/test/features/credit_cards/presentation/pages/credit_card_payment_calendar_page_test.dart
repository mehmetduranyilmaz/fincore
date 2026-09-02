import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_payment_calendar.dart';
import 'package:fincore_app/features/credit_cards/presentation/pages/credit_card_payment_calendar_page.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_payment_calendar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders month rows followed by each year total', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          creditCardPaymentCalendarProvider.overrideWith(
            (ref) async => _calendar,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: CreditCardPaymentCalendarPage(referenceDate: DateTime(2026, 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aylık Ödeme Takvimi'), findsOneWidget);
    expect(find.text('2025-10'), findsOneWidget);
    expect(find.text('2025-11'), findsOneWidget);
    expect(find.text('2025-12'), findsOneWidget);
    expect(find.text('2026-01'), findsOneWidget);
    expect(find.text('2025 Yılı Toplamı'), findsOneWidget);
    expect(find.text('2026 Yılı Toplamı'), findsOneWidget);
    expect(find.text('600,00 ₺'), findsOneWidget);
    expect(find.text('1 kesinleşmiş • 1 planlanan'), findsNWidgets(2));
    expect(find.text('Müşteri • Mehmet Eğitim'), findsOneWidget);
    expect(find.text('Kredi Kartı • Akbank Axess • ****0349'), findsOneWidget);

    await tester.tap(find.byKey(const Key('payment_calendar_toggle_details')));
    await tester.pumpAndSettle();

    expect(find.text('Detayları Göster'), findsOneWidget);
    expect(find.text('Müşteri • Mehmet Eğitim'), findsNothing);

    await tester.tap(find.byKey(const Key('payment_calendar_toggle_details')));
    await tester.pumpAndSettle();

    expect(find.text('Detayları Gizle'), findsOneWidget);
    expect(find.text('Müşteri • Mehmet Eğitim'), findsOneWidget);

    await tester.tap(find.byKey(const Key('payment_calendar_toggle_months')));
    await tester.pumpAndSettle();

    expect(find.text('Ayları Göster'), findsOneWidget);
    expect(find.text('2025-10'), findsNothing);
    expect(find.text('2026-01'), findsNothing);
    expect(find.text('2025 Yılı Toplamı'), findsOneWidget);
    expect(find.text('2026 Yılı Toplamı'), findsOneWidget);
    expect(find.text('Müşteri • Mehmet Eğitim'), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('payment_calendar_toggle_details')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('payment_calendar_toggle_months')));
    await tester.pumpAndSettle();

    expect(find.text('Ayları Gizle'), findsOneWidget);
    expect(find.text('2025-10'), findsOneWidget);
    expect(find.text('2026-01'), findsOneWidget);
    expect(find.text('Müşteri • Mehmet Eğitim'), findsNothing);
    expect(find.text('Detayları Göster'), findsOneWidget);

    await tester.tap(find.byKey(const Key('payment_calendar_toggle_details')));
    await tester.pumpAndSettle();

    expect(find.text('Müşteri • Mehmet Eğitim'), findsOneWidget);
  });
}

final _calendar = CreditCardPaymentCalendar([
  CreditCardPaymentYear(
    year: 2025,
    months: [
      CreditCardPaymentMonth(
        year: 2025,
        month: 10,
        totalsByCurrency: const {'TRY': 100},
        transactionCount: 1,
        details: [
          CreditCardPaymentDetail(
            sourceId: 'customer-1',
            kind: CreditCardPaymentDetailKind.customer,
            label: 'Müşteri • Mehmet Eğitim',
            totalsByCurrency: const {'TRY': 100},
            transactionCount: 1,
          ),
        ],
      ),
      CreditCardPaymentMonth(
        year: 2025,
        month: 11,
        totalsByCurrency: const {'TRY': 200},
        transactionCount: 2,
        plannedExpenseCount: 1,
        details: [
          CreditCardPaymentDetail(
            sourceId: 'card-1',
            kind: CreditCardPaymentDetailKind.creditCard,
            label: 'Kredi Kartı • Akbank Axess • ****0349',
            totalsByCurrency: const {'TRY': 200},
            transactionCount: 2,
            plannedExpenseCount: 1,
          ),
        ],
      ),
      CreditCardPaymentMonth(
        year: 2025,
        month: 12,
        totalsByCurrency: const {'TRY': 300},
        transactionCount: 3,
      ),
    ],
    totalsByCurrency: const {'TRY': 600},
  ),
  CreditCardPaymentYear(
    year: 2026,
    months: [
      CreditCardPaymentMonth(
        year: 2026,
        month: 1,
        totalsByCurrency: const {'TRY': 400},
        transactionCount: 4,
      ),
    ],
    totalsByCurrency: const {'TRY': 400},
  ),
]);
