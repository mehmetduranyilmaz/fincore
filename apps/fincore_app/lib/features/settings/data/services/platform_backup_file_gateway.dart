import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' as selector;
import 'package:fincore_app/features/settings/domain/services/backup_file_gateway.dart';
import 'package:share_plus/share_plus.dart';

final class PlatformBackupFileGateway implements BackupFileGateway {
  const PlatformBackupFileGateway();

  static const selector.XTypeGroup _backupFiles = selector.XTypeGroup(
    label: 'Fincore yedekleri',
    extensions: ['fincorebackup'],
    mimeTypes: ['application/json'],
    uniformTypeIdentifiers: ['public.json'],
    webWildCards: ['application/json'],
  );

  @override
  Future<void> share({
    required String fileName,
    required List<int> bytes,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Fincore şifreli veri yedeği',
        text: 'Bu dosyayı ve parolasını güvenli ve ayrı yerlerde saklayın.',
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType: 'application/json',
          ),
        ],
        fileNameOverrides: [fileName],
      ),
    );
  }

  @override
  Future<List<int>?> pick() async {
    final file = await selector.openFile(
      acceptedTypeGroups: const [_backupFiles],
      confirmButtonText: 'Yedeği Seç',
    );
    return file?.readAsBytes();
  }
}
