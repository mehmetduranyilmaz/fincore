import 'dart:io';

import 'package:fincore_app/features/transactions/domain/errors/receipt_scan_exception.dart';
import 'package:fincore_app/features/transactions/domain/services/receipt_scanner.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

final class ImagePickerReceiptImagePicker implements ReceiptImagePicker {
  ImagePickerReceiptImagePicker(this._imagePicker);

  final ImagePicker _imagePicker;

  @override
  Future<String?> pickImage(ReceiptImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source == ReceiptImageSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 92,
        requestFullMetadata: false,
      );
      return image?.path;
    } on PlatformException catch (error) {
      throw ReceiptScanException(_pickerErrorMessage(error));
    }
  }

  static String _pickerErrorMessage(PlatformException error) {
    return switch (error.code) {
      'camera_access_denied' || 'camera_access_denied_without_prompt' =>
        'Kamera izni verilmedi. Telefon ayarlarından Hesabım için kamera iznini açın.',
      'photo_access_denied' || 'photo_access_denied_without_prompt' =>
        'Galeri izni verilmedi. Telefon ayarlarından Hesabım için fotoğraf iznini açın.',
      'no_available_camera' => 'Telefonda kullanılabilir kamera bulunamadı.',
      _ => 'Fiş görseli açılamadı. Kamerayı veya galeriyi yeniden deneyin.',
    };
  }
}

final class MlKitReceiptTextRecognizer implements ReceiptTextRecognizer {
  const MlKitReceiptTextRecognizer();

  @override
  Future<String> recognizeText(String imagePath) async {
    final imageFile = File(imagePath);
    if (!await imageFile.exists() || await imageFile.length() == 0) {
      throw const ReceiptScanException(
        'Seçilen fiş görseline erişilemedi. Görseli yeniden seçin.',
      );
    }
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);
      return result.text;
    } on PlatformException catch (error) {
      throw ReceiptScanException(_recognizerErrorMessage(error));
    } finally {
      await recognizer.close();
    }
  }

  static String _recognizerErrorMessage(PlatformException error) {
    final detail = '${error.code} ${error.message ?? ''}'.toLowerCase();
    if (detail.contains('image') ||
        detail.contains('bitmap') ||
        detail.contains('format')) {
      return 'Fiş görselinin biçimi okunamadı. Görseli JPG veya PNG olarak yeniden deneyin.';
    }
    return 'Fiş okuma servisi başlatılamadı. Uygulamayı kapatıp yeniden açarak tekrar deneyin.';
  }
}
