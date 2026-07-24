import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

abstract final class ErrorMapper {
  static String map(Object error) {
    return switch (error) {
      DioException() => 'Sunucuya ulaşılamadı.',
      SocketException() => 'İnternet bağlantısı bulunamadı.',
      TimeoutException() => 'İstek zaman aşımına uğradı.',
      _ => 'Beklenmeyen bir hata oluştu.',
    };
  }
}
