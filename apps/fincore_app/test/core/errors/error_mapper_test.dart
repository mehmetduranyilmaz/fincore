import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/transactions/domain/errors/receipt_scan_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps DioException to a server error message', () {
    final error = DioException(requestOptions: RequestOptions());

    expect(ErrorMapper.map(error), 'Sunucuya ulaşılamadı.');
  });

  test('maps SocketException to a connection error message', () {
    const error = SocketException('Connection failed');

    expect(ErrorMapper.map(error), 'İnternet bağlantısı bulunamadı.');
  });

  test('maps TimeoutException to a timeout error message', () {
    final error = TimeoutException('Request timed out');

    expect(ErrorMapper.map(error), 'İstek zaman aşımına uğradı.');
  });

  test('maps unknown errors to a fallback message', () {
    final error = Exception('Unknown');

    expect(ErrorMapper.map(error), 'Beklenmeyen bir hata oluştu.');
  });

  test('preserves an actionable receipt scan error', () {
    const error = ReceiptScanException('Fiş görseline erişilemedi.');

    expect(ErrorMapper.map(error), 'Fiş görseline erişilemedi.');
  });
}
