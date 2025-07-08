import 'package:injectable/injectable.dart';

import '../../../../core/services/backend_api_service.dart';
import 'auth_remote_datasource.dart';

@Injectable(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final BackendApiService _apiService;

  AuthRemoteDataSourceImpl(this._apiService);

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
    bool requireBiometric = false,
  }) async {
    return await _apiService.login(
      email: email,
      password: password,
      requireBiometric: requireBiometric,
    );
  }

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _apiService.register(
      email: email,
      password: password,
      name: name,
    );
  }

  @override
  Future<void> logout() async {
    await _apiService.logout();
  }

  @override
  Future<UserProfile> getUserProfile() async {
    return await _apiService.getUserProfile();
  }

  @override
  Future<bool> refreshToken() async {
    // The token refresh is handled automatically by the API service interceptor
    try {
      await _apiService.getUserProfile();
      return true;
    } catch (e) {
      return false;
    }
  }
}
