import 'package:fincore_app/features/transactions/domain/services/receipt_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

final class ImagePickerReceiptImagePicker implements ReceiptImagePicker {
  ImagePickerReceiptImagePicker(this._imagePicker);

  final ImagePicker _imagePicker;

  @override
  Future<String?> pickImage(ReceiptImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source == ReceiptImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 92,
      requestFullMetadata: false,
    );
    return image?.path;
  }
}

final class MlKitReceiptTextRecognizer implements ReceiptTextRecognizer {
  const MlKitReceiptTextRecognizer();

  @override
  Future<String> recognizeText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
