import 'package:dio/dio.dart';
import 'package:fincore_app/core/network/api_client.dart';
import 'package:fincore_app/core/network/refresh_token_coordinator.dart';
import 'package:fincore_app/core/storage/access_token_reader.dart';

final class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._dio,
    this._accessTokenReader,
    this._refreshTokenCoordinator,
  );

  static const String _retriedKey = 'authRetryAttempted';

  final Dio _dio;
  final AccessTokenReader _accessTokenReader;
  final RefreshTokenCoordinator _refreshTokenCoordinator;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[ApiClient.requiresAuthKey] == false) {
      handler.next(options);
      return;
    }

    try {
      final accessToken = await _accessTokenReader.getAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers.putIfAbsent(
          'Authorization',
          () => 'Bearer $accessToken',
        );
      }

      handler.next(options);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final requiresAuth = request.extra[ApiClient.requiresAuthKey] != false;
    final alreadyRetried = request.extra[_retriedKey] == true;

    if (err.response?.statusCode != 401 || !requiresAuth || alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      final accessToken = await _refreshTokenCoordinator.refresh();

      if (accessToken.isEmpty) {
        throw StateError('Refreshed access token is empty');
      }

      request.extra[_retriedKey] = true;
      request.headers['Authorization'] = 'Bearer $accessToken';

      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: request,
          response: err.response,
          type: DioExceptionType.unknown,
          error: error,
          stackTrace: stackTrace,
          message: 'Session refresh failed',
        ),
      );
    }
  }
}
