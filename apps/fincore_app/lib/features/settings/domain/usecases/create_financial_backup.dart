import 'package:fincore_app/features/settings/domain/errors/backup_exception.dart';
import 'package:fincore_app/features/settings/domain/services/backup_codec.dart';
import 'package:fincore_app/features/settings/domain/services/backup_file_gateway.dart';
import 'package:fincore_app/features/settings/domain/services/financial_backup_store.dart';

typedef BackupClock = DateTime Function();

final class CreateFinancialBackupUseCase {
  CreateFinancialBackupUseCase(
    this._store,
    this._codec,
    this._fileGateway, {
    BackupClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final FinancialBackupStore _store;
  final BackupCodec _codec;
  final BackupFileGateway _fileGateway;
  final BackupClock _clock;

  Future<String> execute(String password) async {
    _validatePassword(password);
    final createdAt = _clock().toUtc();
    final bytes = await _codec.encrypt(
      data: await _store.readFinancialData(),
      password: password,
      createdAt: createdAt,
    );
    final fileName = _fileName(createdAt);
    await _fileGateway.share(fileName: fileName, bytes: bytes);
    return fileName;
  }

  static void _validatePassword(String password) {
    if (password.length < 8) {
      throw const BackupException('Yedek parolası en az 8 karakter olmalıdır.');
    }
  }

  static String _fileName(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return 'fincore_${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}.fincorebackup';
  }
}
