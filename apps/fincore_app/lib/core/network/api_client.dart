import 'package:dio/dio.dart';
import 'package:fincore_app/core/network/exceptions/api_exception.dart';

final class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T?> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return _request<T>(
      'GET',
      path,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<T?> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return _request<T>(
      'POST',
      path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<T?> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return _request<T>(
      'PUT',
      path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<T?> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return _request<T>(
      'DELETE',
      path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<T?> _request<T>(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, headers: headers),
      );

      return response.data;
    } on DioException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ApiException(
          message:
              error.response?.statusMessage ??
              error.message ??
              'Network request failed',
          statusCode: error.response?.statusCode,
          data: error.response?.data,
        ),
        stackTrace,
      );
    }
  }
}
