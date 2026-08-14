import 'package:fincore_app/features/settings/domain/errors/backup_exception.dart';
import 'package:fincore_app/features/settings/domain/services/backup_codec.dart';
import 'package:fincore_app/features/settings/domain/services/backup_file_gateway.dart';
import 'package:fincore_app/features/settings/domain/services/financial_backup_store.dart';

final class RestoreFinancialBackupUseCase {
  const RestoreFinancialBackupUseCase(
    this._store,
    this._codec,
    this._fileGateway,
  );

  final FinancialBackupStore _store;
  final BackupCodec _codec;
  final BackupFileGateway _fileGateway;

  Future<bool> execute(String password) async {
    if (password.length < 8) {
      throw const BackupException('Yedek parolası en az 8 karakter olmalıdır.');
    }
    final bytes = await _fileGateway.pick();
    if (bytes == null) return false;
    final data = await _codec.decrypt(bytes: bytes, password: password);
    await _store.replaceFinancialData(data);
    return true;
  }
}
