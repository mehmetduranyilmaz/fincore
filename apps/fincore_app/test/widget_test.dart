import 'package:fincore_app/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('displays the splash page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FincoreApp()));

    expect(find.text('Fincore'), findsOneWidget);
  });
}
