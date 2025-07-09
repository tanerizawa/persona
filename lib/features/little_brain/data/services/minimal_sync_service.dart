import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/logging_service.dart';
import '../models/hive_models.dart';

@injectable
class MinimalSyncService {
  static const String _baseUrl = 'http://localhost:3000'; // TODO: Replace with actual server URL
  static const String _tokenKey = 'minimal_sync_token';
  static const String _deviceIdKey = 'minimal_device_id';
  static const String _lastSyncKey = 'minimal_last_sync_';

  final LoggingService _logger = LoggingService();
  String? _cachedToken;
  String? _cachedDeviceId;

  // Authentication
  Future<String?> _getAuthToken() async {
    if (_cachedToken != null) return _cachedToken;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<void> _saveAuthToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String> _getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedDeviceId = prefs.getString(_deviceIdKey);
    
    if (_cachedDeviceId == null) {
      _cachedDeviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_deviceIdKey, _cachedDeviceId!);
    }
    
    return _cachedDeviceId!;
  }

  // Authentication methods
  Future<MinimalSyncResult> registerUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveAuthToken(data['token']);
        
        _logger.info('User registered successfully');
        return MinimalSyncResult.success('User registered successfully');
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Registration failed';
        return MinimalSyncResult.failure(error);
      }
    } catch (e) {
      _logger.error('Registration error: $e');
      return MinimalSyncResult.failure('Network error: ${e.toString()}');
    }
  }

  Future<MinimalSyncResult> loginUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthToken(data['token']);
        
        _logger.info('User logged in successfully');
        return MinimalSyncResult.success('Login successful');
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Login failed';
        return MinimalSyncResult.failure(error);
      }
    } catch (e) {
      _logger.error('Login error: $e');
      return MinimalSyncResult.failure('Network error: ${e.toString()}');
    }
  }

  // Sync operations
  Future<MinimalSyncResult> pushMemories(List<HiveMemory> memories) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return MinimalSyncResult.failure('User not authenticated');
      }

      // Convert memories to JSON format
      final items = memories.map((memory) => {
        'entity_id': memory.id,
        'data': {
          'id': memory.id,
          'content': memory.content,
          'tags': memory.tags,
          'contexts': memory.contexts,
          'emotionalWeight': memory.emotionalWeight,
          'timestamp': memory.timestamp.toIso8601String(),
          'source': memory.source,
          'metadata': memory.metadata,
        },
      }).toList();

      final response = await http.post(
        Uri.parse('$_baseUrl/sync/push'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data_type': 'memories',
          'items': items,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('Pushed ${data['synced_count']} memories to server');
        
        // Update last sync timestamp
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('${_lastSyncKey}memories', DateTime.now().toIso8601String());
        
        return MinimalSyncResult.success(
          'Pushed ${data['synced_count']} memories successfully',
          data: data,
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Push sync failed';
        return MinimalSyncResult.failure(error);
      }
    } catch (e) {
      _logger.error('Push memories error: $e');
      return MinimalSyncResult.failure('Push failed: ${e.toString()}');
    }
  }

  Future<MinimalSyncResult> pullMemories() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return MinimalSyncResult.failure('User not authenticated');
      }

      // Get last sync timestamp for incremental sync
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString('${_lastSyncKey}memories');
      
      final uri = Uri.parse('$_baseUrl/sync/pull/memories');
      final uriWithQuery = lastSync != null 
          ? uri.replace(queryParameters: {'since': lastSync})
          : uri;

      final response = await http.get(
        uriWithQuery,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>;
        
        final memories = items.map((item) {
          final memoryData = item['data'] as Map<String, dynamic>;
          return HiveMemory(
            id: memoryData['id'],
            content: memoryData['content'],
            tags: List<String>.from(memoryData['tags'] ?? []),
            contexts: List<String>.from(memoryData['contexts'] ?? []),
            emotionalWeight: memoryData['emotionalWeight']?.toDouble() ?? 0.0,
            timestamp: DateTime.parse(memoryData['timestamp']),
            source: memoryData['source'] ?? 'sync',
            metadata: Map<String, dynamic>.from(memoryData['metadata'] ?? {}),
          );
        }).toList();
        
        _logger.info('Pulled ${memories.length} memories from server');
        
        // Update last sync timestamp
        if (data['sync_timestamp'] != null) {
          await prefs.setString('${_lastSyncKey}memories', data['sync_timestamp']);
        }
        
        return MinimalSyncResult.success(
          'Pulled ${memories.length} memories successfully',
          data: memories,
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Pull sync failed';
        return MinimalSyncResult.failure(error);
      }
    } catch (e) {
      _logger.error('Pull memories error: $e');
      return MinimalSyncResult.failure('Pull failed: ${e.toString()}');
    }
  }

  Future<MinimalSyncResult> pushPersonalityProfile(HivePersonalityProfile profile) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return MinimalSyncResult.failure('User not authenticated');
      }

      final items = [{
        'entity_id': profile.userId,
        'data': {
          'userId': profile.userId,
          'traits': profile.traits,
          'interests': profile.interests,
          'values': profile.values,
          'communicationPatterns': profile.communicationPatterns,
          'lastUpdated': profile.lastUpdated.toIso8601String(),
          'memoryCount': profile.memoryCount,
        },
      }];

      final response = await http.post(
        Uri.parse('$_baseUrl/sync/push'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data_type': 'personality_profile',
          'items': items,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('Pushed personality profile to server');
        return MinimalSyncResult.success('Personality profile synced', data: data);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Profile sync failed';
        return MinimalSyncResult.failure(error);
      }
    } catch (e) {
      _logger.error('Push personality profile error: $e');
      return MinimalSyncResult.failure('Profile sync failed: ${e.toString()}');
    }
  }

  Future<MinimalSyncResult> getSyncStatus() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return MinimalSyncResult.failure('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/sync/status'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MinimalSyncResult.success('Sync status retrieved', data: data);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Status check failed';
        return MinimalSyncResult.failure(error);
      }
    } catch (e) {
      _logger.error('Sync status error: $e');
      return MinimalSyncResult.failure('Status check failed: ${e.toString()}');
    }
  }

  Future<MinimalSyncResult> updateDeviceMetadata() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return MinimalSyncResult.failure('User not authenticated');
      }

      final deviceId = await _getDeviceId();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/sync/device'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'device_id': deviceId}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return MinimalSyncResult.success('Device metadata updated');
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Device sync failed';
        return MinimalSyncResult.failure(error);
      }
    } catch (e) {
      _logger.error('Device metadata error: $e');
      return MinimalSyncResult.failure('Device sync failed: ${e.toString()}');
    }
  }

  // Health check
  Future<bool> isServerHealthy() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      _logger.warning('Server health check failed: $e');
      return false;
    }
  }

  // Full sync operation (memories + personality profile)
  Future<MinimalSyncResult> performFullSync(
    List<HiveMemory> localMemories,
    HivePersonalityProfile? personalityProfile,
  ) async {
    try {
      _logger.info('Starting full sync operation');
      
      // 1. Check server health
      if (!await isServerHealthy()) {
        return MinimalSyncResult.failure('Server is not available');
      }

      // 2. Update device metadata
      final deviceResult = await updateDeviceMetadata();
      if (!deviceResult.isSuccess) {
        _logger.warning('Device metadata sync failed: ${deviceResult.message}');
      }

      // 3. Push local memories
      final pushMemoriesResult = await pushMemories(localMemories);
      if (!pushMemoriesResult.isSuccess) {
        return MinimalSyncResult.failure('Failed to push memories: ${pushMemoriesResult.message}');
      }

      // 4. Push personality profile if available
      MinimalSyncResult? pushProfileResult;
      if (personalityProfile != null) {
        pushProfileResult = await pushPersonalityProfile(personalityProfile);
        if (!pushProfileResult.isSuccess) {
          _logger.warning('Failed to push personality profile: ${pushProfileResult.message}');
        }
      }

      // 5. Pull remote memories
      final pullResult = await pullMemories();
      if (!pullResult.isSuccess) {
        return MinimalSyncResult.failure('Failed to pull memories: ${pullResult.message}');
      }

      final remoteMemories = pullResult.data as List<HiveMemory>? ?? [];
      
      _logger.info('Full sync completed: pushed ${localMemories.length}, pulled ${remoteMemories.length} memories');
      
      return MinimalSyncResult.success(
        'Full sync completed successfully',
        data: {
          'pushed_memories': localMemories.length,
          'pulled_memories': remoteMemories.length,
          'remote_memories': remoteMemories,
          'profile_synced': pushProfileResult?.isSuccess ?? false,
        },
      );
    } catch (e) {
      _logger.error('Full sync error: $e');
      return MinimalSyncResult.failure('Full sync failed: ${e.toString()}');
    }
  }

  // Get sync statistics for UI
  Future<Map<String, dynamic>> getSyncStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncMemories = prefs.getString('${_lastSyncKey}memories');
    final isAuthenticated = await _getAuthToken() != null;
    final isServerHealthy = await this.isServerHealthy();
    
    return {
      'is_authenticated': isAuthenticated,
      'server_healthy': isServerHealthy,
      'last_sync_memories': lastSyncMemories,
      'device_id': await _getDeviceId(),
      'server_url': _baseUrl,
    };
  }

  // Logout and clear auth
  Future<void> logout() async {
    _cachedToken = null;
    _cachedDeviceId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_deviceIdKey);
    // Keep last sync timestamps for reference
    _logger.info('User logged out and auth cleared');
  }

  // Clear all sync data
  Future<void> clearSyncData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('minimal_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    _cachedToken = null;
    _cachedDeviceId = null;
    _logger.info('All sync data cleared');
  }
}

// Simple result class for minimal sync operations
class MinimalSyncResult {
  final bool isSuccess;
  final String message;
  final dynamic data;
  final DateTime timestamp;

  MinimalSyncResult.success(this.message, {this.data}) 
      : isSuccess = true, timestamp = DateTime.now();
  
  MinimalSyncResult.failure(this.message, {this.data}) 
      : isSuccess = false, timestamp = DateTime.now();

  @override
  String toString() {
    return 'MinimalSyncResult(success: $isSuccess, message: $message, timestamp: $timestamp)';
  }
}
