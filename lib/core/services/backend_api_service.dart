import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../constants/app_constants.dart';
import '../models/crisis_models.dart';
import 'secure_storage_service.dart';
import 'biometric_auth_service.dart';
import 'error_tracking_service.dart';
import 'performance_service.dart';

@singleton
class BackendApiService {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  final BiometricAuthService _biometricAuth;
  final ErrorTrackingService _errorTracking;
  final PerformanceService _performance;

  // Prevent multiple concurrent token refresh attempts
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  BackendApiService(
    this._dio,
    this._secureStorage,
    this._biometricAuth,
    this._errorTracking,
    this._performance,
  ) {
    _setupInterceptors();
  }
  
  // Expose dio for other services to use
  Dio get dio => _dio;

  // Callback for auth failure (to be set by AuthBloc)
  void Function()? onAuthFailure;

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // Add authentication token to headers
            final token = await _secureStorage.getAuthToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }

            // Add device information for security
            final deviceId = await _secureStorage.getOrCreateDeviceId();
            options.headers['X-Device-ID'] = deviceId;

            // Add app information
            options.headers['X-App-Version'] = AppConstants.appVersion;
            options.headers['X-Platform'] = 'android';
            options.headers['Content-Type'] = 'application/json';

            handler.next(options);
          } catch (e) {
            debugPrint('Request interceptor error: $e');
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Authentication failed',
                type: DioExceptionType.cancel,
              ),
            );
          }
        },
        onResponse: (response, handler) {
          // Handle successful responses
          handler.next(response);
        },
        onError: (error, handler) async {
          // Handle token expiration
          if (error.response?.statusCode == 401) {
            final refreshed = await _safeRefreshToken();
            if (refreshed) {
              // Retry the original request
              final options = error.requestOptions;
              final token = await _secureStorage.getAuthToken();
              options.headers['Authorization'] = 'Bearer $token';
              
              try {
                final response = await _dio.fetch(options);
                handler.resolve(response);
                return;
              } catch (e) {
                // If retry fails, proceed with original error
              }
            } else {
              // Token refresh failed, redirect to login
              await _handleAuthenticationFailure();
            }
          }
          
          handler.next(error);
        },
      ),
    ]);
  }

  // Authentication endpoints
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _performance.executeWithTracking(
      'api_register',
      () async {
        try {
          final deviceId = await _secureStorage.getOrCreateDeviceId();
          final response = await _dio.post(
            '${AppConstants.backendBaseUrl}/api/auth/register',
            data: {
              'email': email,
              'password': password,
              'name': name,
              'deviceId': deviceId,
            },
          );

          final authResponse = AuthResponse.fromJson(response.data);
          await _storeAuthTokens(authResponse);
          return authResponse;
        } on DioException catch (e) {
          throw _handleApiError(e);
        }
      },
    );
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
    bool requireBiometric = false,
  }) async {
    try {
      // Check biometric authentication if required
      if (requireBiometric) {
        final biometricResult = await _biometricAuth.authenticateWithBiometric();
        if (!biometricResult) {
          throw AuthenticationException('Biometric authentication failed');
        }
      }

      final deviceId = await _secureStorage.getOrCreateDeviceId();
      debugPrint('🔑 Logging in with device ID: $deviceId');
      
      final response = await _dio.post(
        '${AppConstants.backendBaseUrl}/api/auth/login',
        data: {
          'email': email,
          'password': password,
          'deviceId': deviceId,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _storeAuthTokens(authResponse);
      return authResponse;
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<void> logout() async {
    try {
      final token = await _secureStorage.getAuthToken();
      if (token != null) {
        await _dio.post(
          '${AppConstants.backendBaseUrl}/api/auth/logout',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _secureStorage.clearAuthData();
      await _biometricAuth.clearSession();
    }
  }

  // AI Chat endpoints (proxied through backend)
  Future<ChatResponse> sendChatMessage({
    required String message,
    String? conversationId,
    String? model,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.backendBaseUrl}/api/chat/send',
        data: {
          'content': message,
          if (conversationId != null) 'conversationId': conversationId,
        },
      );

      return ChatResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<List<ConversationSummary>> getConversations() async {
    try {
      final response = await _dio.get(
        '${AppConstants.backendBaseUrl}/api/chat/conversations',
      );

      return (response.data['conversations'] as List)
          .map((item) => ConversationSummary.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<ConversationDetail> getConversationHistory(String conversationId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.backendBaseUrl}/api/chat/conversations/$conversationId',
      );

      return ConversationDetail.fromJson(response.data['conversation']);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _dio.delete(
        '${AppConstants.backendBaseUrl}/api/chat/conversations/$conversationId',
      );
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<void> clearAllConversations() async {
    try {
      await _dio.delete(
        '${AppConstants.backendBaseUrl}/api/chat/conversations',
      );
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // User profile endpoints
  Future<UserProfile> getUserProfile() async {
    try {
      final response = await _dio.get(
        '${AppConstants.backendBaseUrl}/user/profile',
      );

      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<UserProfile> updateUserProfile({
    String? name,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final response = await _dio.put(
        '${AppConstants.backendBaseUrl}/user/profile',
        data: {
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
          if (preferences != null) 'preferences': preferences,
        },
      );

      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // Usage and quota endpoints
  Future<UsageStats> getUsageStats() async {
    try {
      final response = await _dio.get(
        '${AppConstants.backendBaseUrl}/user/usage',
      );

      return UsageStats.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // Sync endpoints for Little Brain and mood data
  Future<SyncStatus> getSyncStatus(String deviceId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.backendBaseUrl}/api/sync/status/$deviceId',
      );

      return SyncStatus.fromJson(response.data['syncStatus']);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<SyncStatus> updateSyncStatus({
    required String deviceId,
    required String dataHash,
    required int syncVersion,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.backendBaseUrl}/api/sync/status',
        data: {
          'deviceId': deviceId,
          'dataHash': dataHash,
          'syncVersion': syncVersion,
        },
      );

      return SyncStatus.fromJson(response.data['syncStatus']);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<List<SyncConflict>> getSyncConflicts() async {
    try {
      final response = await _dio.get(
        '${AppConstants.backendBaseUrl}/api/sync/conflicts',
      );

      return (response.data['conflicts'] as List)
          .map((conflict) => SyncConflict.fromJson(conflict))
          .toList();
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<BackupResult> createBackup({
    required String encryptedData,
    required int dataSize,
    required String checksum,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.backendBaseUrl}/api/sync/backup',
        data: {
          'encryptedData': encryptedData,
          'dataSize': dataSize,
          'checksum': checksum,
        },
      );

      return BackupResult.fromJson(response.data['backup']);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<BackupResult?> getLatestBackup() async {
    try {
      final response = await _dio.get(
        '${AppConstants.backendBaseUrl}/api/sync/backup/latest',
      );

      return response.data['backup'] != null 
          ? BackupResult.fromJson(response.data['backup'])
          : null;
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // Biometric authentication endpoints
  Future<void> setupBiometric({
    required String deviceId,
    required String biometricHash,
    String? biometricType,
  }) async {
    try {
      await _dio.post(
        '${AppConstants.backendBaseUrl}/api/auth/biometric/setup',
        data: {
          'deviceId': deviceId,
          'biometricHash': biometricHash,
          if (biometricType != null) 'biometricType': biometricType,
        },
      );
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<bool> verifyBiometric({
    required String deviceId,
    required String biometricHash,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.backendBaseUrl}/api/auth/biometric/verify',
        data: {
          'deviceId': deviceId,
          'biometricHash': biometricHash,
        },
      );

      return response.data['success'] == true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return false; // Invalid biometric
      }
      throw _handleApiError(e);
    }
  }

  Future<void> disableBiometric({
    required String deviceId,
  }) async {
    try {
      await _dio.post(
        '${AppConstants.backendBaseUrl}/api/auth/biometric/disable',
        data: {
          'deviceId': deviceId,
        },
      );
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  // Safe refresh token method that prevents concurrent calls
  Future<bool> _safeRefreshToken() async {
    // If already refreshing, wait for the current refresh to complete
    if (_isRefreshing) {
      if (_refreshCompleter != null) {
        return await _refreshCompleter!.future;
      }
      return false;
    }

    // Start refreshing
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final result = await _refreshToken();
      _refreshCompleter!.complete(result);
      return result;
    } catch (e) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  // Private helper methods
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('❌ No refresh token available');
        return false;
      }

      final deviceId = await _secureStorage.getOrCreateDeviceId();
      debugPrint('🔄 Refreshing token with device ID: $deviceId');
      debugPrint('🔑 Using refresh token: ${refreshToken.substring(0, 20)}...');

      final response = await _dio.post(
        '${AppConstants.backendBaseUrl}/api/auth/refresh',
        data: {
          'refreshToken': refreshToken,
          'deviceId': deviceId,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      
      debugPrint('🔄 Received new refresh token: ${authResponse.refreshToken.substring(0, 20)}...');
      
      // CRITICAL: Store new tokens immediately and validate
      await _storeAuthTokens(authResponse);
      
      // Validation: Verify tokens were stored correctly
      final storedRefreshToken = await _secureStorage.getRefreshToken();
      if (storedRefreshToken != authResponse.refreshToken) {
        debugPrint('⚠️ Token storage validation failed!');
        debugPrint('   Expected: ${authResponse.refreshToken.substring(0, 20)}...');
        debugPrint('   Got:      ${storedRefreshToken?.substring(0, 20)}...');
        throw Exception('Token storage failed');
      }
      
      debugPrint('✅ Refresh token updated and validated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
      return false;
    }
  }

  Future<void> _storeAuthTokens(AuthResponse authResponse) async {
    await _secureStorage.saveAuthToken(authResponse.accessToken, authResponse.refreshToken);
    
    if (authResponse.user != null) {
      await _secureStorage.saveUserId(authResponse.user!.id);
    }
  }

  Future<void> _handleAuthenticationFailure() async {
    await _secureStorage.clearAuthData();
    await _biometricAuth.clearSession();
    if (onAuthFailure != null) onAuthFailure!();
  }

  ApiException _handleApiError(DioException error) {
    final endpoint = error.requestOptions.path;
    final method = error.requestOptions.method;
    final statusCode = error.response?.statusCode;
    
    // Track API error for analytics
    _errorTracking.trackApiError(
      '$method $endpoint',
      statusCode ?? 0,
      error.toString(),
      duration: error.requestOptions.receiveTimeout?.inMilliseconds,
      requestData: {
        'method': method,
        'path': endpoint,
        'headers': error.requestOptions.headers,
      },
    );

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Connection timeout. Please check your internet connection.');
      
      case DioExceptionType.connectionError:
        return ApiException('Unable to connect to server. Please try again later.');
      
      case DioExceptionType.badResponse:
        final message = error.response?.data?['message'] ?? 'An error occurred';
        
        switch (statusCode) {
          case 400:
            return ApiException('Invalid request: $message');
          case 401:
            return AuthenticationException('Authentication failed');
          case 403:
            return ApiException('Access denied: $message');
          case 404:
            return ApiException('Resource not found');
          case 429:
            return ApiException('Too many requests. Please try again later.');
          case 500:
            return ApiException('Server error. Please try again later.');
          default:
            return ApiException('Error $statusCode: $message');
        }
      
      default:
        return ApiException('An unexpected error occurred');
    }
  }

  // Crisis Intervention endpoints
  Future<void> logCrisisEvent({
    required String crisisLevel,
    required String triggerSource,
    required List<String> detectedKeywords,
    String? userMessage,
  }) async {
    try {
      await _dio.post(
        '${AppConstants.backendBaseUrl}/api/crisis/log-crisis',
        data: {
          'crisisLevel': crisisLevel,
          'triggerSource': triggerSource,
          'detectedKeywords': detectedKeywords,
          if (userMessage != null) 'userMessage': userMessage,
        },
      );
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<void> recordIntervention({
    required String crisisEventId,
    required String interventionType,
    List<String>? resourcesProvided,
    bool professionalContactMade = false,
  }) async {
    try {
      await _dio.post(
        '${AppConstants.backendBaseUrl}/api/crisis/record-intervention',
        data: {
          'crisisEventId': crisisEventId,
          'interventionType': interventionType,
          'resourcesProvided': resourcesProvided ?? [],
          'professionalContactMade': professionalContactMade,
        },
      );
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<List<CrisisEvent>> getCrisisHistory() async {
    try {
      final response = await _dio.get(
        '${AppConstants.backendBaseUrl}/api/crisis/crisis-history',
      );

      return (response.data['data'] as List<dynamic>)
          .map((e) => CrisisEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<CrisisResources> getCrisisResources({String language = 'id'}) async {
    try {
      final response = await _dio.get(
        '${AppConstants.backendBaseUrl}/api/crisis/crisis-resources',
        queryParameters: {'language': language},
      );

      return CrisisResources.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleApiError(e);
    }
  }
}

// Data models
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User? user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final String? bio;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.preferences,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      bio: json['bio'],
      preferences: json['preferences'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'bio': bio,
      'preferences': preferences,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert User to UserProfile (for state management)
  UserProfile toUserProfile() {
    return UserProfile(
      id: id,
      email: email,
      name: name,
      bio: bio,
      preferences: preferences,
      createdAt: createdAt,
      updatedAt: DateTime.now(), // Use current time as updated time
    );
  }
}

class ChatResponse {
  final String conversationId;
  final List<ChatMessage> messages;

  ChatResponse({
    required this.conversationId,
    required this.messages,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      conversationId: json['conversation']['id'],
      messages: (json['conversation']['messages'] as List)
          .map((item) => ChatMessage.fromJson(item))
          .toList(),
    );
  }
}

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: json['role'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      metadata: json['metadata'],
    );
  }
}

class ConversationDetail {
  final String id;
  final String? title;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  ConversationDetail({
    required this.id,
    this.title,
    required this.createdAt,
    required this.messages,
  });

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    return ConversationDetail(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      messages: (json['messages'] as List)
          .map((item) => ChatMessage.fromJson(item))
          .toList(),
    );
  }
}

class ConversationSummary {
  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LastMessage? lastMessage;

  ConversationSummary({
    required this.id,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastMessage: json['lastMessage'] != null 
          ? LastMessage.fromJson(json['lastMessage'])
          : null,
    );
  }
}

class LastMessage {
  final String content;
  final String role;
  final DateTime createdAt;

  LastMessage({
    required this.content,
    required this.role,
    required this.createdAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      content: json['content'],
      role: json['role'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? bio;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      bio: json['bio'],
      preferences: json['preferences'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class UsageStats {
  final int messagesUsed;
  final int messagesLimit;
  final double costUsed;
  final double costLimit;
  final DateTime resetDate;

  UsageStats({
    required this.messagesUsed,
    required this.messagesLimit,
    required this.costUsed,
    required this.costLimit,
    required this.resetDate,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      messagesUsed: json['messagesUsed'],
      messagesLimit: json['messagesLimit'],
      costUsed: json['costUsed'].toDouble(),
      costLimit: json['costLimit'].toDouble(),
      resetDate: DateTime.parse(json['resetDate']),
    );
  }
}

class SyncStatus {
  final String id;
  final String userId;
  final String deviceId;
  final DateTime lastSyncTimestamp;
  final int syncVersion;
  final String? dataHash;
  final bool isActive;

  SyncStatus({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.lastSyncTimestamp,
    required this.syncVersion,
    this.dataHash,
    required this.isActive,
  });

  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      id: json['id'],
      userId: json['userId'],
      deviceId: json['deviceId'],
      lastSyncTimestamp: DateTime.parse(json['lastSyncTimestamp']),
      syncVersion: json['syncVersion'],
      dataHash: json['dataHash'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceId': deviceId,
      'lastSyncTimestamp': lastSyncTimestamp.toIso8601String(),
      'syncVersion': syncVersion,
      'dataHash': dataHash,
      'isActive': isActive,
    };
  }
}

class SyncConflict {
  final String deviceId1;
  final String deviceId2;
  final DateTime timestamp1;
  final DateTime timestamp2;
  final String? dataHash1;
  final String? dataHash2;
  final String conflictType;

  SyncConflict({
    required this.deviceId1,
    required this.deviceId2,
    required this.timestamp1,
    required this.timestamp2,
    this.dataHash1,
    this.dataHash2,
    required this.conflictType,
  });

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      deviceId1: json['deviceId1'],
      deviceId2: json['deviceId2'],
      timestamp1: DateTime.parse(json['timestamp1']),
      timestamp2: DateTime.parse(json['timestamp2']),
      dataHash1: json['dataHash1'],
      dataHash2: json['dataHash2'],
      conflictType: json['conflictType'],
    );
  }
}

class BackupResult {
  final String id;
  final String deviceId;
  final String dataHash;
  final int dataSize;
  final String checksum;
  final DateTime createdAt;

  BackupResult({
    required this.id,
    required this.deviceId,
    required this.dataHash,
    required this.dataSize,
    required this.checksum,
    required this.createdAt,
  });

  factory BackupResult.fromJson(Map<String, dynamic> json) {
    return BackupResult(
      id: json['id'],
      deviceId: json['deviceId'],
      dataHash: json['dataHash'],
      dataSize: json['dataSize'],
      checksum: json['checksum'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

// Exception classes
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}

class AuthenticationException extends ApiException {
  AuthenticationException(super.message);
  
  @override
  String toString() => 'AuthenticationException: $message';
}
