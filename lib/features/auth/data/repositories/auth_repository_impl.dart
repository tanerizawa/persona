import 'package:injectable/injectable.dart';

import '../../../../core/services/backend_api_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;
  final BiometricAuthService _biometricAuth;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._secureStorage,
    this._biometricAuth,
  );

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
    bool requireBiometric = false,
  }) async {
    return await _remoteDataSource.login(
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
    return await _remoteDataSource.register(
      email: email,
      password: password,
      name: name,
    );
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.logout();
    await _secureStorage.clearAuthData();
    await _biometricAuth.clearSession();
  }

  @override
  Future<UserProfile> getUserProfile() async {
    return await _remoteDataSource.getUserProfile();
  }

  @override
  Future<bool> refreshToken() async {
    return await _remoteDataSource.refreshToken();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _secureStorage.isAuthenticated();
  }

  @override
  Future<void> enableBiometricAuth() async {
    await _secureStorage.setBiometricEnabled(true);
  }

  @override
  Future<bool> authenticateWithBiometric() async {
    if (!await _secureStorage.isBiometricEnabled()) {
      return false;
    }
    
    if (!await _biometricAuth.isBiometricAvailable()) {
      return false;
    }
    
    return await _biometricAuth.authenticateWithBiometric();
  }
}
