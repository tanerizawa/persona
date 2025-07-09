import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'secure_storage_service.dart';
import 'backend_api_service.dart';
import 'logging_service.dart';


/// Service untuk autentikasi biometrik dan manajemen session
class BiometricAuthService {
  static BiometricAuthService? _instance;
  static BiometricAuthService get instance => _instance ??= BiometricAuthService._();
  
  BiometricAuthService._();
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _storage = SecureStorageService.instance;
  final LoggingService _logger = LoggingService();
  
  // Keys untuk session management
  static const String _sessionTokenKey = 'session_token';
  static const String _biometricHashKey = 'biometric_hash';
  static const String _lastAuthTimeKey = 'last_auth_time';
  
  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }
  
  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }
  
  /// Setup biometric authentication for user with backend integration
  Future<bool> setupBiometricAuth(String userId, BackendApiService? backendApi) async {
    try {
      // First check if biometric is available
      if (!await isBiometricAvailable()) {
        throw BiometricException('Biometric authentication not available');
      }
      
      // Authenticate with biometric to setup
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Setup biometric authentication for Persona',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (isAuthenticated) {
        // Generate biometric hash for verification
        final biometricHash = _generateBiometricHash(userId);
        await _storage.setBiometricEnabled(true);
        await _storage.storeSecure(_biometricHashKey, biometricHash);
        
        // Setup biometric in backend if API service is available
        if (backendApi != null) {
          try {
            final deviceId = await _storage.getOrCreateDeviceId();
            await backendApi.setupBiometric(
              deviceId: deviceId,
              biometricHash: biometricHash,
              biometricType: 'fingerprint',
            );
          } catch (e) {
            // If backend setup fails, still allow local biometric setup
            // This provides fallback for offline scenarios
            _logger.warning('Backend biometric setup failed', e);
          }
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      throw BiometricException('Failed to setup biometric auth: $e');
    }
  }
  
  /// Authenticate with biometric and verify with backend
  Future<bool> authenticateWithBiometric({BackendApiService? backendApi}) async {
    try {
      if (!await _storage.isBiometricEnabled()) {
        return false;
      }
      
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Persona',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (isAuthenticated) {
        await _updateLastAuthTime();
        
        // Verify with backend if API service is available
        if (backendApi != null) {
          try {
            final deviceId = await _storage.getOrCreateDeviceId();
            final biometricHash = await _storage.retrieveSecure(_biometricHashKey);
            
            if (biometricHash != null) {
              final backendVerified = await backendApi.verifyBiometric(
                deviceId: deviceId,
                biometricHash: biometricHash,
              );
              return backendVerified;
            }
          } catch (e) {
            // If backend verification fails, fallback to local verification
            _logger.warning('Backend biometric verification failed: $e');
          }
        }
        
        return true; // Local authentication successful
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Disable biometric authentication with backend sync
  Future<void> disableBiometricAuth({BackendApiService? backendApi}) async {
    await _storage.setBiometricEnabled(false);
    await _storage.deleteSecure(_biometricHashKey);
    
    // Disable biometric in backend if API service is available
    if (backendApi != null) {
      try {
        final deviceId = await _storage.getOrCreateDeviceId();
        await backendApi.disableBiometric(deviceId: deviceId);
      } catch (e) {
        // Log error but don't throw - local disable should still work
        _logger.error('Backend biometric disable failed: $e');
      }
    }
  }
  
  /// Check if session is still valid
  Future<bool> isSessionValid() async {
    try {
      final lastAuthTime = await _getLastAuthTime();
      if (lastAuthTime == null) return false;
      
      final now = DateTime.now();
      final sessionDuration = now.difference(lastAuthTime);
      
      // Session expires after 30 minutes of inactivity
      return sessionDuration.inMinutes < 30;
    } catch (e) {
      return false;
    }
  }
  
  /// Generate session token for API requests
  Future<String?> generateSessionToken(String userId) async {
    try {
      final deviceId = await _storage.getOrCreateDeviceId();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final tokenData = {
        'userId': userId,
        'deviceId': deviceId,
        'timestamp': timestamp,
        'nonce': _generateNonce(),
      };
      
      final tokenJson = jsonEncode(tokenData);
      final encryptedToken = await _storage.encryptData(tokenJson);
      
      // Store session token
    await _storage.storeSecure(_sessionTokenKey, encryptedToken);
      
      return encryptedToken;
    } catch (e) {
      return null;
    }
  }
  
  /// Get current session token
  Future<String?> getSessionToken() async {
    try {
      if (!await isSessionValid()) {
        await clearSession();
        return null;
      }
      
      return await _storage.retrieveSecure(_sessionTokenKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Clear current session
  Future<void> clearSession() async {
    await _storage.deleteSecure(_sessionTokenKey);
    await _storage.deleteSecure(_lastAuthTimeKey);
  }
  
  /// Validate session token integrity
  Future<bool> validateSessionToken(String token) async {
    try {
      final decryptedJson = await _storage.decryptData(token);
      final tokenData = jsonDecode(decryptedJson) as Map<String, dynamic>;
      
      // Check if token is not too old (max 24 hours)
      final timestamp = tokenData['timestamp'] as int;
      final tokenAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      const maxAge = 24 * 60 * 60 * 1000; // 24 hours
      
      if (tokenAge > maxAge) {
        return false;
      }
      
      // Verify device ID matches
      final tokenDeviceId = tokenData['deviceId'] as String;
      final currentDeviceId = await _storage.getOrCreateDeviceId();
      
      return tokenDeviceId == currentDeviceId;
    } catch (e) {
      return false;
    }
  }
  
  String _generateBiometricHash(String userId) {
    final data = '$userId${DateTime.now().millisecondsSinceEpoch}';
    return sha256.convert(utf8.encode(data)).toString();
  }
  
  String _generateNonce() {
    final random = List.generate(16, (i) => DateTime.now().microsecondsSinceEpoch + i);
    return sha256.convert(random.map((e) => e % 256).toList()).toString().substring(0, 16);
  }
  
  Future<void> _updateLastAuthTime() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _storage.storeSecure(_lastAuthTimeKey, timestamp);
  }
  
  Future<DateTime?> _getLastAuthTime() async {
    try {
      final timestampStr = await _storage.retrieveSecure(_lastAuthTimeKey);
      if (timestampStr == null) return null;
      
      final timestamp = int.parse(timestampStr);
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }
}

/// Exception untuk biometric authentication errors
class BiometricException implements Exception {
  final String message;
  BiometricException(this.message);
  
  @override
  String toString() => 'BiometricException: $message';
}
