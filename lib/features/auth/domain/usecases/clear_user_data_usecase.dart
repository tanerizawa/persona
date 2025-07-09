// ignore_for_file: avoid_print

import 'package:injectable/injectable.dart';

import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../chat/data/datasources/chat_local_datasource.dart';
import '../../../little_brain/domain/usecases/little_brain_local_usecases.dart';

/// Use case untuk membersihkan semua data user saat logout atau switch account
@injectable
class ClearUserDataUseCase {
  final SecureStorageService _secureStorage;
  final BiometricAuthService _biometricAuth;
  final ChatLocalDataSource _chatDataSource;
  final ClearAllLocalDataUseCase _clearLittleBrainData;

  ClearUserDataUseCase(
    this._secureStorage,
    this._biometricAuth,
    this._chatDataSource,
    this._clearLittleBrainData,
  );

  /// Clear all user-specific data while preserving device settings
  Future<void> call({bool preserveDeviceId = true}) async {
    try {
      // 1. Clear authentication data
      await _secureStorage.clearAuthData();
      
      // 2. Clear biometric session
      await _biometricAuth.clearSession();
      
      // 3. Clear chat history
      await _chatDataSource.clearConversation();
      
      // 4. Clear Little Brain memories and profile
      await _clearLittleBrainData.call();
      
      // 5. Clear all secure storage if not preserving device settings
      if (!preserveDeviceId) {
        await _secureStorage.clearAllData();
      }
      
      print('✅ [UserManagement] All user data cleared successfully');
    } catch (e) {
      print('❌ [UserManagement] Failed to clear user data: $e');
      throw Exception('Failed to clear user data: $e');
    }
  }

  /// Clear only session-related data (for session timeout, not full logout)
  Future<void> clearSessionOnly() async {
    try {
      await _secureStorage.clearAuthData();
      await _biometricAuth.clearSession();
      print('✅ [UserManagement] Session data cleared');
    } catch (e) {
      print('❌ [UserManagement] Failed to clear session data: $e');
      throw Exception('Failed to clear session data: $e');
    }
  }

  /// Emergency clear all data (for account security issues)
  Future<void> emergencyClearAll() async {
    try {
      await _secureStorage.clearAllData();
      await _biometricAuth.clearSession();
      await _chatDataSource.clearConversation();
      await _clearLittleBrainData.call();
      print('🚨 [UserManagement] Emergency data clear completed');
    } catch (e) {
      print('❌ [UserManagement] Emergency clear failed: $e');
      // Don't throw - emergency clear should always succeed
    }
  }
}
