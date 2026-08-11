import 'package:fincore_app/features/transactions/domain/entities/receipt_scan_draft.dart';
import 'package:fincore_app/features/transactions/domain/services/receipt_scanner.dart';
import 'package:fincore_app/features/transactions/domain/usecases/parse_receipt_text.dart';

final class ScanReceiptUseCase {
  const ScanReceiptUseCase(this._picker, this._recognizer, this._parser);

  final ReceiptImagePicker _picker;
  final ReceiptTextRecognizer _recognizer;
  final ParseReceiptTextUseCase _parser;

  Future<ReceiptScanDraft?> execute(ReceiptImageSource source) async {
    final imagePath = await _picker.pickImage(source);
    if (imagePath == null) {
      return null;
    }
    final text = await _recognizer.recognizeText(imagePath);
    if (text.trim().isEmpty) {
      throw const FormatException('No text found on receipt.');
    }
    return _parser.execute(text);
  }
}
