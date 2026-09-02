import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' as selector;
import 'package:fincore_app/features/settings/domain/services/backup_file_gateway.dart';
import 'package:share_plus/share_plus.dart';

final class PlatformBackupFileGateway implements BackupFileGateway {
  const PlatformBackupFileGateway();

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
      // Android storage providers do not consistently assign a MIME type to
      // the custom .fincorebackup extension. The authenticated envelope and
      // payload are strictly validated before any data is replaced.
      confirmButtonText: 'Yedeği Seç',
    );
    return file?.readAsBytes();
  }
}
