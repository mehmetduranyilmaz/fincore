import 'package:dio/dio.dart';
import 'package:fincore_app/core/config/environment.dart';
import 'package:fincore_app/core/network/api_client.dart';
import 'package:fincore_app/core/network/interceptors/auth_interceptor.dart';
import 'package:fincore_app/core/network/interceptors/logging_interceptor.dart';
import 'package:fincore_app/core/network/interceptors/retry_interceptor.dart';
import 'package:fincore_app/core/storage/token_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final environmentProvider = Provider<Environment>((ref) => Environment.dev);

final dioProvider = Provider<Dio>((ref) {
  final environment = ref.watch(environmentProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: environment.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(ref.watch(tokenStorageProvider)),
    RetryInterceptor(),
    if (kDebugMode) LoggingInterceptor(),
  ]);

  ref.onDispose(dio.close);

  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
