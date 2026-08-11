enum ReceiptImageSource { camera, gallery }

abstract interface class ReceiptImagePicker {
  Future<String?> pickImage(ReceiptImageSource source);
}

abstract interface class ReceiptTextRecognizer {
  Future<String> recognizeText(String imagePath);
}
