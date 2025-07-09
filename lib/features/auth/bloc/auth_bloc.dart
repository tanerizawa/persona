import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/services/backend_api_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/biometric_auth_service.dart';
import '../../../core/services/user_session_service.dart';
import '../domain/usecases/clear_user_data_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final BackendApiService _apiService;
  final SecureStorageService _secureStorage;
  final BiometricAuthService _biometricAuth;
  final ClearUserDataUseCase _clearUserData;
  final UserSessionService _userSessionService;

  AuthBloc(
    this._apiService,
    this._secureStorage,
    this._biometricAuth,
    this._clearUserData,
    this._userSessionService,
  ) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthBiometricLoginRequested>(_onAuthBiometricLoginRequested);
    on<AuthTokenRefreshRequested>(_onAuthTokenRefreshRequested);

    // Listen for forced logout from backend service (e.g. refresh token expired)
    _apiService.onAuthFailure = () {
      add(AuthLogoutRequested());
    };
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      final isAuthenticated = await _secureStorage.isAuthenticated();
      if (!isAuthenticated) {
        emit(AuthUnauthenticated());
        return;
      }

      // Check if session is still valid
      final isSessionValid = await _biometricAuth.isSessionValid();
      if (!isSessionValid) {
        emit(AuthUnauthenticated());
        return;
      }

      // Get user profile to verify token validity
      try {
        final userProfile = await _apiService.getUserProfile();
        emit(AuthAuthenticated(user: userProfile));
      } catch (e) {
        // Token might be invalid, try to refresh
        add(AuthTokenRefreshRequested());
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to check authentication: $e'));
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final authResponse = await _apiService.login(
        email: event.email,
        password: event.password,
        requireBiometric: event.requireBiometric,
      );

      if (authResponse.user != null) {
        // Generate session token for secure local access
        await _biometricAuth.generateSessionToken(authResponse.user!.id);
        
        // Update user session service to detect user changes
        await _userSessionService.updateCurrentUser();
        
        emit(AuthAuthenticated(user: authResponse.user!.toUserProfile()));
      } else {
        emit(AuthError(message: 'Login failed: Invalid response'));
      }
    } on AuthenticationException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'Login failed: $e'));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final authResponse = await _apiService.register(
        email: event.email,
        password: event.password,
        name: event.name,
      );

      if (authResponse.user != null) {
        // Generate session token for secure local access
        await _biometricAuth.generateSessionToken(authResponse.user!.id);
        
        // Update user session service to detect user changes
        await _userSessionService.updateCurrentUser();
        
        emit(AuthAuthenticated(user: authResponse.user!.toUserProfile()));
      } else {
        emit(AuthError(message: 'Registration failed: Invalid response'));
      }
    } on ApiException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'Registration failed: $e'));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      // Use comprehensive user data clearing
      await _clearUserData.call();
      
      // Try to logout from server (but don't fail if it doesn't work)
      try {
        await _apiService.logout();
      } catch (e) {
        // Server logout failed, but local data is already cleared
        print('⚠️ Server logout failed (local data already cleared): $e');
      }
      
      // Update user session service to detect user changes
      await _userSessionService.updateCurrentUser();
      
      emit(AuthUnauthenticated());
    } catch (e) {
      // Fallback: manual cleanup if use case fails
      try {
        await _secureStorage.clearAuthData();
        await _biometricAuth.clearSession();
      } catch (fallbackError) {
        print('❌ Fallback cleanup failed: $fallbackError');
      }
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthBiometricLoginRequested(
    AuthBiometricLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      // Check if biometric is available and enabled
      if (!await _biometricAuth.isBiometricAvailable()) {
        emit(AuthError(message: 'Biometric authentication not available'));
        return;
      }

      if (!await _secureStorage.isBiometricEnabled()) {
        emit(AuthError(message: 'Biometric authentication not enabled'));
        return;
      }

      // Authenticate with biometric
      final isAuthenticated = await _biometricAuth.authenticateWithBiometric();
      if (!isAuthenticated) {
        emit(AuthError(message: 'Biometric authentication failed'));
        return;
      }

      // Check if we have valid tokens
      final isTokenValid = await _secureStorage.isAuthenticated();
      if (!isTokenValid) {
        emit(AuthError(message: 'No valid authentication tokens found'));
        return;
      }

      // Get user profile to complete authentication
      try {
        final userProfile = await _apiService.getUserProfile();
        emit(AuthAuthenticated(user: userProfile));
      } catch (e) {
        // Token might be invalid, try to refresh
        add(AuthTokenRefreshRequested());
      }
    } catch (e) {
      emit(AuthError(message: 'Biometric login failed: $e'));
    }
  }

  Future<void> _onAuthTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // The token refresh is handled automatically by the API service interceptor
      // We just need to verify if the refresh was successful
      final userProfile = await _apiService.getUserProfile();
      emit(AuthAuthenticated(user: userProfile));
    } catch (e) {
      // Refresh failed, user needs to login again
      await _secureStorage.clearAuthData();
      await _biometricAuth.clearSession();
      emit(AuthUnauthenticated());
    }
  }
}
