import 'package:fincore_app/core/network/api_client.dart';
import 'package:fincore_app/core/network/exceptions/api_exception.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/data/models/login_request_dto.dart';
import 'package:fincore_app/features/auth/data/models/login_response_dto.dart';
import 'package:fincore_app/features/auth/data/models/refresh_token_request_dto.dart';

final class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl({required this.apiClient});

  static const String _loginEndpoint = '/auth/login';
  static const String _refreshEndpoint = '/auth/refresh';

  final ApiClient apiClient;

  @override
  Future<LoginResponseDto> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequestDto(email: email, password: password);
    final responseJson = await apiClient.post<Map<String, dynamic>>(
      _loginEndpoint,
      data: request.toJson(),
    );

    if (responseJson == null) {
      throw const ApiException(message: 'Login response body is empty');
    }

    return LoginResponseDto.fromJson(responseJson);
  }

  @override
  Future<LoginResponseDto> refresh({required String refreshToken}) async {
    final request = RefreshTokenRequestDto(refreshToken: refreshToken);
    final responseJson = await apiClient.post<Map<String, dynamic>>(
      _refreshEndpoint,
      data: request.toJson(),
      requiresAuth: false,
    );

    if (responseJson == null) {
      throw const ApiException(message: 'Refresh response body is empty');
    }

    return LoginResponseDto.fromJson(responseJson);
  }

  @override
  Future<void> logout() {
    // TODO(fincore): Call the logout endpoint with apiClient.
    return Future<void>.value();
  }
}
