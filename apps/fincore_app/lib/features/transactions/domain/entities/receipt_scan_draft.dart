final class ReceiptScanDraft {
  const ReceiptScanDraft({
    required this.rawText,
    this.totalAmount,
    this.description,
    this.transactionDate,
    this.lastFourDigits,
    this.installmentCount,
    this.suggestedCategoryId,
  });

  final String rawText;
  final double? totalAmount;
  final String? description;
  final DateTime? transactionDate;
  final String? lastFourDigits;
  final int? installmentCount;
  final String? suggestedCategoryId;
}
