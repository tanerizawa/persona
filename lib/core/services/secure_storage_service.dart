import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

/// Service untuk mengelola penyimpanan data sensitif dengan enkripsi
class SecureStorageService {
  static SecureStorageService? _instance;
  static SecureStorageService get instance => _instance ??= SecureStorageService._();
  
  SecureStorageService._();
  
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
  
  /// Generate unique device ID
  Future<String> getOrCreateDeviceId() async {
    String? deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId?.isEmpty ?? true) {
      deviceId = await _generateDeviceId();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }
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
  
  // Private methods
  Future<String> _generateDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = '${androidInfo.id}_${androidInfo.model}_${androidInfo.device}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = '${iosInfo.identifierForVendor}_${iosInfo.model}';
      } else {
        // Fallback untuk platform lain
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        deviceId = 'device_$timestamp';
      }
      
      // Hash untuk privasi dan konsistensi
      final bytes = utf8.encode(deviceId);
      return sha256.convert(bytes).toString().substring(0, 32);
    } catch (e) {
      // Fallback jika device info gagal
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = List.generate(16, (index) => timestamp + index);
      final bytes = Uint8List.fromList(random.map((e) => e % 256).toList());
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
