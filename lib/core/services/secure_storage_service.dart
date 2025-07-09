import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'logging_service.dart';

/// Service untuk mengelola penyimpanan data sensitif dengan enkripsi
class SecureStorageService {
  static SecureStorageService? _instance;
  static SecureStorageService get instance => _instance ??= SecureStorageService._();
  
  SecureStorageService._();
  
  final LoggingService _logger = LoggingService();
  
  // Cache untuk device ID
  static String? _cachedDeviceId;
  
  // Konfigurasi Secure Storage
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    sharedPreferencesName: 'persona_secure_prefs',
    preferencesKeyPrefix: 'persona_',
  );
  
  static const IOSOptions _iosOptions = IOSOptions(
    groupId: 'group.com.persona.ai.assistant',
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );
  
  // Keys untuk data sensitif
  static const String _userTokenKey = 'user_auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _deviceIdKey = 'device_id';
  static const String _encryptionKeyKey = 'encryption_key';
  static const String _biometricEnabledKey = 'biometric_enabled';
  
  /// Generate unique device ID with caching
  Future<String> getOrCreateDeviceId() async {
    // Return cached device ID if available
    if (_cachedDeviceId != null) {
      _logger.debug('🔧 Using cached device ID: $_cachedDeviceId');
      return _cachedDeviceId!;
    }
    
    String? deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId?.isEmpty ?? true) {
      deviceId = await _generateStableDeviceId();
      await _storage.write(key: _deviceIdKey, value: deviceId);
      _logger.info('🔧 Generated new device ID: $deviceId');
    } else {
      _logger.info('🔧 Using existing device ID: $deviceId');
    }
    
    // Cache the device ID for future use
    _cachedDeviceId = deviceId;
    return deviceId!;
  }
  
  /// Simpan token autentikasi
  Future<void> saveAuthToken(String token, String refreshToken) async {
    try {
      await _storage.write(key: _userTokenKey, value: token);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      throw SecurityException('Failed to save auth tokens: $e');
    }
  }
  
  /// Ambil token autentikasi
  Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _userTokenKey);
    } catch (e) {
      throw SecurityException('Failed to retrieve auth token: $e');
    }
  }
  
  /// Ambil refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      throw SecurityException('Failed to retrieve refresh token: $e');
    }
  }
  
  /// Simpan user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }
  
  /// Ambil user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }
  
  /// Generate dan simpan encryption key untuk data lokal
  Future<String> getOrCreateEncryptionKey() async {
    String? key = await _storage.read(key: _encryptionKeyKey);
    if (key?.isEmpty ?? true) {
      key = _generateEncryptionKey();
      await _storage.write(key: _encryptionKeyKey, value: key);
    }
    return key!;
  }
  
  /// Enkripsi data sensitif
  Future<String> encryptData(String data) async {
    try {
      final key = await getOrCreateEncryptionKey();
      final bytes = utf8.encode(data);
      final keyBytes = utf8.encode(key);
      
      // Simple XOR encryption untuk demonstration
      // Untuk produksi, gunakan AES atau algoritma enkripsi yang lebih kuat
      final encrypted = <int>[];
      for (int i = 0; i < bytes.length; i++) {
        encrypted.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return base64.encode(encrypted);
    } catch (e) {
      throw SecurityException('Failed to encrypt data: $e');
    }
  }
  
  /// Dekripsi data sensitif
  Future<String> decryptData(String encryptedData) async {
    try {
      final key = await getOrCreateEncryptionKey();
      final encrypted = base64.decode(encryptedData);
      final keyBytes = utf8.encode(key);
      
      final decrypted = <int>[];
      for (int i = 0; i < encrypted.length; i++) {
        decrypted.add(encrypted[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      throw SecurityException('Failed to decrypt data: $e');
    }
  }
  
  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }
  
  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// General secure storage methods
  Future<void> storeSecure(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw SecurityException('Failed to store secure data: $e');
    }
  }

  Future<String?> retrieveSecure(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw SecurityException('Failed to retrieve secure data: $e');
    }
  }
  
  /// Hapus semua data autentikasi (logout)
  Future<void> clearAuthData() async {
    try {
      await _storage.delete(key: _userTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userIdKey);
      // Jangan hapus device ID dan encryption key
    } catch (e) {
      throw SecurityException('Failed to clear auth data: $e');
    }
  }
  
  /// Hapus semua data (uninstall/reset)
  Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecurityException('Failed to clear all data: $e');
    }
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    final userId = await getUserId();
    return token != null && token.isNotEmpty && userId != null && userId.isNotEmpty;
  }
  
  /// Clear device ID for testing purposes
  Future<void> clearDeviceId() async {
    await _storage.delete(key: _deviceIdKey);
    _logger.info('🔧 Device ID cleared');
  }

  /// Debug method to show current device ID
  Future<void> debugDeviceId() async {
    final deviceId = await _storage.read(key: _deviceIdKey);
    _logger.info('🔧 Current stored device ID: $deviceId');
    final newDeviceId = await getOrCreateDeviceId();
    _logger.info('🔧 Device ID after getOrCreate: $newDeviceId');
  }

  // Private methods
  Future<String> _generateStableDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceIdentifier;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Use more stable identifiers for Android
        // Combine multiple fields for better stability
        final identifierParts = [
          androidInfo.model,
          androidInfo.manufacturer, 
          androidInfo.device,
          androidInfo.display,
          androidInfo.hardware,
        ];
        deviceIdentifier = identifierParts.join('_');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // iOS identifierForVendor is stable per app install
        deviceIdentifier = '${iosInfo.identifierForVendor}_${iosInfo.model}';
      } else {
        // Fallback for other platforms - use a consistent string
        deviceIdentifier = 'persona_app_device_fallback';
      }
      
      // Hash the identifier for privacy and to get consistent length
      final bytes = utf8.encode(deviceIdentifier);
      final hash = sha256.convert(bytes).toString();
      
      _logger.info('🔧 Device identifier base: ${deviceIdentifier.substring(0, 20)}...');
      _logger.info('🔧 Generated hash: ${hash.substring(0, 16)}...');
      
      return hash.substring(0, 32);
    } catch (e) {
      _logger.warning('⚠️ Device info failed, using fallback: $e');
      // More stable fallback - same hash every time for this app
      final fallbackString = 'persona_ai_assistant_stable_fallback';
      final bytes = utf8.encode(fallbackString);
      return sha256.convert(bytes).toString().substring(0, 32);
    }
  }
  
  /// Delete specific secure data
  Future<void> deleteSecure(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw SecurityException('Failed to delete secure data: $e');
    }
  }
  
  String _generateEncryptionKey() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = List.generate(32, (index) => timestamp + index);
    final bytes = Uint8List.fromList(random.map((e) => e % 256).toList());
    return sha256.convert(bytes).toString();
  }
}

/// Custom exception untuk security errors
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}
