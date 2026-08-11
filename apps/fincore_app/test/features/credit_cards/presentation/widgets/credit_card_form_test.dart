import 'package:fincore_app/core/widgets/bank_icon.dart';
import 'package:fincore_app/features/credit_cards/presentation/widgets/credit_card_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selects the card bank from the shared icon catalog', (
    tester,
  ) async {
    CreditCardFormValue? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CreditCardForm(
              onCancel: () {},
              onSubmit: (value) => submitted = value,
            ),
          ),
        ),
      ),
    );

    final bankSelector = find.byKey(const Key('credit_card_bank_selector'));
    expect(bankSelector, findsOneWidget);
    expect(
      find.descendant(of: bankSelector, matching: find.byType(EditableText)),
      findsNothing,
    );

    await tester.tap(bankSelector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akbank').last);
    await tester.pumpAndSettle();

    expect(find.text('Akbank'), findsOneWidget);
    expect(find.byType(BankIcon), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kart Adı'),
      'Sağlam Kart',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kartın Son 4 Hanesi'),
      '1234',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kart Limiti'),
      '25000',
    );
    final saveButton = find.text('Kaydet');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(submitted?.bankName, 'Akbank');
    expect(submitted?.creditLimit, 25000);
  });
}
