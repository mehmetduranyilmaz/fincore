import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fincore_app/core/network/api_client.dart';
import 'package:fincore_app/core/network/interceptors/auth_interceptor.dart';
import 'package:fincore_app/core/network/refresh_token_coordinator.dart';
import 'package:fincore_app/core/storage/access_token_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refreshes once and retries a 401 request with the new token', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.fincore.test'));
    final adapter = _UnauthorizedThenSuccessAdapter();
    var refreshCallCount = 0;
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        dio,
        const _AccessTokenReader('expired_access_token'),
        RefreshTokenCoordinator(() async {
          refreshCallCount++;
          return 'new_access_token';
        }),
      ),
    );

    final response = await dio.get<Map<String, dynamic>>(
      '/protected',
      options: Options(extra: {ApiClient.requiresAuthKey: true}),
    );

    expect(response.statusCode, 200);
    expect(refreshCallCount, 1);
    expect(adapter.requestHeaders, hasLength(2));
    expect(
      adapter.requestHeaders.last['Authorization'],
      'Bearer new_access_token',
    );
  });
}

final class _AccessTokenReader implements AccessTokenReader {
  const _AccessTokenReader(this._accessToken);

  final String? _accessToken;

  @override
  Future<String?> getAccessToken() async => _accessToken;
}

final class _UnauthorizedThenSuccessAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> requestHeaders = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestHeaders.add(Map<String, dynamic>.from(options.headers));

    if (requestHeaders.length == 1) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Unauthorized'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'success': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
