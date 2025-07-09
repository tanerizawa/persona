import 'package:flutter/material.dart';
import '../services/lazy_page_service.dart';
import '../services/navigation_analytics_storage.dart';

/// Service untuk preloading halaman berdasarkan usage patterns
class PagePreloadService {
  static final PagePreloadService _instance = PagePreloadService._internal();
  factory PagePreloadService() => _instance;
  PagePreloadService._internal() {
    _loadAnalyticsData();
  }

  final LazyPageService _lazyPageService = LazyPageService();
  final NavigationAnalyticsStorage _storage = NavigationAnalyticsStorage();
  
  // Track user navigation patterns
  final Map<int, int> _pageVisitCount = {};
  final Map<int, DateTime> _lastVisit = {};
  final List<int> _navigationHistory = [];
  
  // Preloading configuration
  static const int _maxHistoryLength = 10;
  static const int _preloadThreshold = 3; // Preload if visited 3+ times

  /// Load analytics data dari persistent storage
  Future<void> _loadAnalyticsData() async {
    final visitCounts = await _storage.loadVisitCounts();
    final lastVisits = await _storage.loadLastVisits();
    final history = await _storage.loadNavigationHistory();
    
    _pageVisitCount.clear();
    _pageVisitCount.addAll(visitCounts);
    
    _lastVisit.clear();
    _lastVisit.addAll(lastVisits);
    
    _navigationHistory.clear();
    _navigationHistory.addAll(history);
  }

  /// Save analytics data ke persistent storage
  Future<void> _saveAnalyticsData() async {
    await Future.wait([
      _storage.saveVisitCounts(_pageVisitCount),
      _storage.saveLastVisits(_lastVisit),
      _storage.saveNavigationHistory(_navigationHistory),
    ]);
  }
  
  /// Record page visit untuk analytics
  Future<void> recordPageVisit(int pageIndex) async {
    _pageVisitCount[pageIndex] = (_pageVisitCount[pageIndex] ?? 0) + 1;
    _lastVisit[pageIndex] = DateTime.now();
    
    _navigationHistory.add(pageIndex);
    if (_navigationHistory.length > _maxHistoryLength) {
      _navigationHistory.removeAt(0);
    }
    
    // Save data secara async
    _saveAnalyticsData();
    
    _analyzeAndPreload();
  }

  /// Analyze navigation patterns dan preload halaman yang sering diakses
  void _analyzeAndPreload() {
    // Preload berdasarkan frequency
    _pageVisitCount.forEach((pageIndex, visitCount) {
      if (visitCount >= _preloadThreshold && !_lazyPageService.isCached(pageIndex)) {
        _schedulePreload(pageIndex);
      }
    });
    
    // Preload berdasarkan navigation sequence
    final nextPage = _predictNextPage();
    if (nextPage != null && !_lazyPageService.isCached(nextPage)) {
      _schedulePreload(nextPage);
    }
  }

  /// Predict halaman berikutnya berdasarkan pattern
  int? _predictNextPage() {
    if (_navigationHistory.length < 2) return null;
    
    final current = _navigationHistory.last;
    
    // Simple pattern: if user often goes A->B, preload B when on A
    final patterns = <List<int>, int>{};
    for (int i = 0; i < _navigationHistory.length - 1; i++) {
      final pattern = [_navigationHistory[i], _navigationHistory[i + 1]];
      patterns[pattern] = (patterns[pattern] ?? 0) + 1;
    }
    
    // Find most common next page after current
    int? mostLikelyNext;
    int maxCount = 0;
    patterns.forEach((pattern, count) {
      if (pattern[0] == current && count > maxCount) {
        maxCount = count;
        mostLikelyNext = pattern[1];
      }
    });
    
    return mostLikelyNext;
  }

  /// Schedule preload untuk halaman (background)
  void _schedulePreload(int pageIndex) {
    // Preload dengan delay untuk tidak mengganggu user experience
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_lazyPageService.isCached(pageIndex)) {
        // Trigger lazy loading untuk page ini
        debugPrint('Preloading page $pageIndex based on usage patterns');
      }
    });
  }

  /// Get frequently accessed pages
  List<int> getFrequentlyAccessedPages() {
    final sortedPages = _pageVisitCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedPages
        .where((entry) => entry.value >= _preloadThreshold)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get navigation analytics
  Map<String, dynamic> getNavigationAnalytics() {
    return {
      'page_visit_counts': _pageVisitCount,
      'last_visits': _lastVisit.map((k, v) => MapEntry(k, v.toIso8601String())),
      'navigation_history': _navigationHistory,
      'frequently_accessed': getFrequentlyAccessedPages(),
      'cache_stats': _lazyPageService.getCacheStats(),
    };
  }

  /// Clear analytics data
  Future<void> clearAnalytics() async {
    _pageVisitCount.clear();
    _lastVisit.clear();
    _navigationHistory.clear();
    
    // Clear persistent storage juga
    await _saveAnalyticsData();
  }
}
