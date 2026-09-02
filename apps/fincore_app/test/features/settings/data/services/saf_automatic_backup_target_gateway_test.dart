import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_app/features/settings/data/services/saf_automatic_backup_target_gateway.dart';
import 'package:saf/saf.dart';

void main() {
  test(
    'accepts the normalized document URI returned by the directory picker',
    () async {
      final gateway = SafAutomaticBackupTargetGateway(
        saf: _FakeSaf(const [
          SafPersistedPermission(
            uri:
                'content://com.android.externalstorage.documents/tree/primary%3AYedekler',
            read: true,
            write: true,
            persistedTime: 1,
          ),
        ]),
      );

      expect(
        await gateway.hasWritePermission(
          'content://com.android.externalstorage.documents/tree/'
          'primary%3AYedekler/document/primary%3AYedekler',
        ),
        isTrue,
      );
    },
  );

  test('rejects a matching URI without write permission', () async {
    final gateway = SafAutomaticBackupTargetGateway(
      saf: _FakeSaf(const [
        SafPersistedPermission(
          uri:
              'content://com.android.externalstorage.documents/tree/primary%3AYedekler',
          read: true,
          write: false,
          persistedTime: 1,
        ),
      ]),
    );

    expect(
      await gateway.hasWritePermission(
        'content://com.android.externalstorage.documents/tree/'
        'primary%3AYedekler/document/primary%3AYedekler',
      ),
      isFalse,
    );
  });
}

final class _FakeSaf extends Saf {
  _FakeSaf(this.permissions);

  final List<SafPersistedPermission> permissions;

  @override
  Future<List<SafPersistedPermission>> persistedPermissions() async =>
      permissions;
}
