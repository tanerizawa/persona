import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menyimpan navigation analytics dan cache secara persistent
class NavigationAnalyticsStorage {
  static final NavigationAnalyticsStorage _instance = NavigationAnalyticsStorage._internal();
  factory NavigationAnalyticsStorage() => _instance;
  NavigationAnalyticsStorage._internal();

  static const String _keyVisitCounts = 'page_visit_counts';
  static const String _keyLastVisits = 'page_last_visits';
  static const String _keyNavigationHistory = 'navigation_history';
  static const String _keyFirstLaunch = 'first_launch';

  /// Save page visit counts
  Future<void> saveVisitCounts(Map<int, int> visitCounts) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(visitCounts.map((k, v) => MapEntry(k.toString(), v)));
    await prefs.setString(_keyVisitCounts, json);
  }

  /// Load page visit counts
  Future<Map<int, int>> loadVisitCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyVisitCounts);
      if (jsonStr == null) return {};
      
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return json.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (e) {
      return {};
    }
  }

  /// Save last visit timestamps  
  Future<void> saveLastVisits(Map<int, DateTime> lastVisits) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(lastVisits.map((k, v) => MapEntry(k.toString(), v.toIso8601String())));
    await prefs.setString(_keyLastVisits, json);
  }

  /// Load last visit timestamps
  Future<Map<int, DateTime>> loadLastVisits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyLastVisits);
      if (jsonStr == null) return {};
      
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return json.map((k, v) => MapEntry(int.parse(k), DateTime.parse(v as String)));
    } catch (e) {
      return {};
    }
  }

  /// Save navigation history
  Future<void> saveNavigationHistory(List<int> history) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(history);
    await prefs.setString(_keyNavigationHistory, json);
  }

  /// Load navigation history
  Future<List<int>> loadNavigationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyNavigationHistory);
      if (jsonStr == null) return [];
      
      final List<dynamic> json = jsonDecode(jsonStr);
      return json.cast<int>();
    } catch (e) {
      return [];
    }
  }

  /// Check if this is first launch
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_keyFirstLaunch);
  }

  /// Mark first launch as complete
  Future<void> markFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }

  /// Clear all analytics data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyVisitCounts),
      prefs.remove(_keyLastVisits),
      prefs.remove(_keyNavigationHistory),
    ]);
  }

  /// Get storage size (approximate)
  Future<Map<String, int>> getStorageInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'visit_counts_size': (prefs.getString(_keyVisitCounts) ?? '').length,
      'last_visits_size': (prefs.getString(_keyLastVisits) ?? '').length,
      'history_size': (prefs.getString(_keyNavigationHistory) ?? '').length,
    };
  }
}
