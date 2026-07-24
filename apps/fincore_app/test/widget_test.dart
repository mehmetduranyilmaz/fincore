import 'package:fincore_app/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('redirects unauthenticated users to login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FincoreApp()));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });
}
