import 'package:fincore_app/features/auth/domain/entities/update_user_credentials_input.dart';
import 'package:fincore_app/features/auth/domain/entities/user_credentials_profile.dart';
import 'package:fincore_app/features/auth/domain/repositories/user_credentials_repository.dart';
import 'package:fincore_app/features/auth/presentation/pages/profile_page.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads current email and validates password confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCredentialsRepositoryProvider.overrideWithValue(_Repository()),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    final emailField = tester.widget<TextFormField>(
      find.descendant(
        of: find.byKey(const Key('profile_email')),
        matching: find.byType(TextFormField),
      ),
    );
    expect(emailField.controller!.text, 'dev@fincore.app');

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('profile_current_password')),
        matching: find.byType(TextFormField),
      ),
      '123456',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('profile_new_password')),
        matching: find.byType(TextFormField),
      ),
      'YeniGuvenli123',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('profile_new_password_confirmation')),
        matching: find.byType(TextFormField),
      ),
      'eslesmiyor123',
    );
    final saveButton = find.byKey(const Key('profile_save'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('Yeni şifreler eşleşmiyor.'), findsOneWidget);
  });
}

final class _Repository implements UserCredentialsRepository {
  @override
  Future<UserCredentialsProfile> getProfile() async =>
      const UserCredentialsProfile(email: 'dev@fincore.app');

  @override
  Future<UserCredentialsProfile> update(
    UpdateUserCredentialsInput input,
  ) async => UserCredentialsProfile(email: input.newEmail);
}
