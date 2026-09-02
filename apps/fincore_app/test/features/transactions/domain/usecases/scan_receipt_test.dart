import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/transactions/domain/errors/receipt_scan_exception.dart';
import 'package:fincore_app/features/transactions/domain/services/receipt_scanner.dart';
import 'package:fincore_app/features/transactions/domain/usecases/parse_receipt_text.dart';
import 'package:fincore_app/features/transactions/domain/usecases/scan_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns parsed suggestions after a successful OCR scan', () async {
    final draft = await ScanReceiptUseCase(
      const _Picker('receipt.jpg'),
      const _Recognizer('TEST MARKET\nTOPLAM 417,00 TL\n21.07.2020'),
      ParseReceiptTextUseCase(const _Categories()),
    ).execute(ReceiptImageSource.gallery);

    expect(draft, isNotNull);
    expect(draft!.totalAmount, 417);
    expect(draft.transactionDate, DateTime(2020, 7, 21));
  });

  test('preserves an actionable OCR failure', () async {
    final useCase = ScanReceiptUseCase(
      const _Picker('receipt.jpg'),
      const _FailingRecognizer(),
      ParseReceiptTextUseCase(const _Categories()),
    );

    expect(
      () => useCase.execute(ReceiptImageSource.camera),
      throwsA(isA<ReceiptScanException>()),
    );
  });
}

final class _Picker implements ReceiptImagePicker {
  const _Picker(this.path);
  final String? path;
  @override
  Future<String?> pickImage(ReceiptImageSource source) async => path;
}

final class _Recognizer implements ReceiptTextRecognizer {
  const _Recognizer(this.text);
  final String text;
  @override
  Future<String> recognizeText(String imagePath) async => text;
}

final class _FailingRecognizer implements ReceiptTextRecognizer {
  const _FailingRecognizer();
  @override
  Future<String> recognizeText(String imagePath) async =>
      throw const ReceiptScanException('OCR başlatılamadı.');
}

final class _Categories implements CategoryRepository {
  const _Categories();
  @override
  Future<List<Category>> getAll() async => const [];
  @override
  Future<Category?> getById(String categoryId) async => null;
  @override
  Future<void> create(Category category) async {}
  @override
  Future<void> update(Category category) async {}
  @override
  Future<void> delete(String categoryId) async {}
}
