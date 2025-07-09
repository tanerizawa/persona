import 'dart:async';
import 'package:injectable/injectable.dart';
import 'secure_storage_service.dart';

@singleton
class UserSessionService {
  final SecureStorageService _secureStorage;
  String? _currentUserId;
  
  // Stream controller for user switches
  final StreamController<String?> _userSwitchController = StreamController<String?>.broadcast();
  
  UserSessionService(this._secureStorage);
  
  /// Stream that emits when user changes
  Stream<String?> get userSwitchStream => _userSwitchController.stream;
  
  /// Get current user ID
  String? get currentUserId => _currentUserId;
  
  /// Initialize and check for user changes
  Future<void> initialize() async {
    _currentUserId = await _secureStorage.getUserId();
  }
  
  /// Check if user has changed and notify listeners
  Future<bool> checkAndNotifyUserChange() async {
    final newUserId = await _secureStorage.getUserId();
    
    if (newUserId != _currentUserId) {
      final previousUserId = _currentUserId;
      _currentUserId = newUserId;
      
      // Notify listeners about user change
      _userSwitchController.add(newUserId);
      
      print('🔄 User switched from ${previousUserId?.substring(0, 8) ?? 'none'} to ${newUserId?.substring(0, 8) ?? 'none'}');
      return true;
    }
    
    return false;
  }
  
  /// Update current user (call this after login/logout)
  Future<void> updateCurrentUser() async {
    await checkAndNotifyUserChange();
  }
  
  void dispose() {
    _userSwitchController.close();
  }
}
