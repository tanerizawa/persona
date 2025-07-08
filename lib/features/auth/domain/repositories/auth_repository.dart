import '../../../../core/services/backend_api_service.dart';

abstract class AuthRepository {
  Future<AuthResponse> login({
    required String email,
    required String password,
    bool requireBiometric = false,
  });
  
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
  });
  
  Future<void> logout();
  
  Future<UserProfile> getUserProfile();
  
  Future<bool> refreshToken();
  
  Future<bool> isAuthenticated();
  
  Future<void> enableBiometricAuth();
  
  Future<bool> authenticateWithBiometric();
}
