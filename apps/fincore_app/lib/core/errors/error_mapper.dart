import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fincore_app/features/credit_cards/domain/errors/credit_card_operation_exception.dart';
import 'package:fincore_app/features/customers/domain/errors/customer_operation_exception.dart';
import 'package:fincore_app/features/accounts/domain/errors/account_operation_exception.dart';
import 'package:fincore_app/features/categories/domain/errors/category_operation_exception.dart';
import 'package:fincore_app/features/auth/domain/errors/user_credentials_exception.dart';
import 'package:fincore_app/features/transactions/domain/errors/receipt_scan_exception.dart';

abstract final class ErrorMapper {
  static String map(Object error) {
    return switch (error) {
      AccountOperationException() => error.message,
      CategoryOperationException() => error.message,
      CreditCardOperationException() => error.message,
      CustomerOperationException() => error.message,
      UserCredentialsException() => error.message,
      ReceiptScanException() => error.message,
      DioException() => 'Sunucuya ulaşılamadı.',
      SocketException() => 'İnternet bağlantısı bulunamadı.',
      TimeoutException() => 'İstek zaman aşımına uğradı.',
      FormatException() =>
        'Fiş bilgileri okunamadı. Daha net bir görüntü deneyin.',
      ArgumentError() => 'Girilen bilgileri kontrol edin.',
      StateError() => 'İşlem mevcut durumda tamamlanamadı.',
      _ => 'Beklenmeyen bir hata oluştu.',
    };
  }
}
