import 'dart:developer' as developer;

import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/transactions/domain/entities/receipt_scan_draft.dart';
import 'package:fincore_app/features/transactions/domain/services/receipt_scanner.dart';
import 'package:fincore_app/features/transactions/domain/usecases/scan_receipt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReceiptScanStatus { initial, scanning, review, failure }

final class ReceiptScanState {
  const ReceiptScanState._({
    required this.status,
    this.draft,
    this.errorMessage,
  });

  const ReceiptScanState.initial() : this._(status: ReceiptScanStatus.initial);
  const ReceiptScanState.scanning()
    : this._(status: ReceiptScanStatus.scanning);
  const ReceiptScanState.review(ReceiptScanDraft draft)
    : this._(status: ReceiptScanStatus.review, draft: draft);
  const ReceiptScanState.failure(String message)
    : this._(status: ReceiptScanStatus.failure, errorMessage: message);

  final ReceiptScanStatus status;
  final ReceiptScanDraft? draft;
  final String? errorMessage;
}

final receiptScanControllerProvider =
    NotifierProvider<ReceiptScanController, ReceiptScanState>(
      ReceiptScanController.new,
    );

final class ReceiptScanController extends Notifier<ReceiptScanState> {
  late ScanReceiptUseCase _scanReceipt;

  @override
  ReceiptScanState build() {
    _scanReceipt = ref.watch(scanReceiptProvider);
    return const ReceiptScanState.initial();
  }

  Future<void> scan(ReceiptImageSource source) async {
    state = const ReceiptScanState.scanning();
    try {
      final draft = await _scanReceipt.execute(source);
      state = draft == null
          ? const ReceiptScanState.initial()
          : ReceiptScanState.review(draft);
    } on Object catch (error, stackTrace) {
      developer.log(
        'Receipt scanning failed.',
        name: 'fincore.receipt_scan',
        error: error,
        stackTrace: stackTrace,
      );
      state = ReceiptScanState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const ReceiptScanState.initial();
  }
}
