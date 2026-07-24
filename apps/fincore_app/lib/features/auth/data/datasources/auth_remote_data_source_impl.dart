import 'package:fincore_app/core/network/api_client.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/data/models/login_request_dto.dart';
import 'package:fincore_app/features/auth/data/models/login_response_dto.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';

final class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequestDto(email: email, password: password);
    final requestJson = request.toJson();

    // TODO(fincore): Send requestJson with apiClient when the endpoint is ready.

    final response = LoginResponseDto.fromJson({
      'accessToken': 'demo_access_token',
      'refreshToken': 'demo_refresh_token',
      'user': {
        'id': '1',
        'fullName': 'Demo User',
        'email': requestJson['email'],
        'isActive': true,
      },
    });

    return response.toEntity();
  }

  @override
  Future<void> logout() {
    // TODO(fincore): Call the logout endpoint with apiClient.
    return Future<void>.value();
  }
}
