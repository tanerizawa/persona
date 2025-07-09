import 'package:flutter/material.dart';

/// Service untuk lazy loading dan caching halaman dengan offline-first approach
class LazyPageService {
  static final LazyPageService _instance = LazyPageService._internal();
  factory LazyPageService() => _instance;
  LazyPageService._internal();

  // Cache untuk halaman yang sudah diload
  final Map<int, Widget> _pageCache = {};
  
  // Track halaman yang sedang loading
  final Set<int> _loadingPages = {};
  
  // Cache metadata untuk optimasi
  final Map<int, DateTime> _lastAccessed = {};
  final Map<int, bool> _isHeavyPage = {};

  /// Menandai halaman sebagai "heavy" yang perlu lazy loading
  void markAsHeavyPage(int pageIndex) {
    _isHeavyPage[pageIndex] = true;
  }

  /// Mengecek apakah halaman sudah ada di cache
  bool isCached(int pageIndex) {
    return _pageCache.containsKey(pageIndex);
  }

  /// Mengecek apakah halaman sedang loading
  bool isLoading(int pageIndex) {
    return _loadingPages.contains(pageIndex);
  }

  /// Mendapatkan halaman dari cache
  Widget? getCachedPage(int pageIndex) {
    if (_pageCache.containsKey(pageIndex)) {
      _lastAccessed[pageIndex] = DateTime.now();
      return _pageCache[pageIndex];
    }
    return null;
  }

  /// Menyimpan halaman ke cache
  void cachePage(int pageIndex, Widget page) {
    _pageCache[pageIndex] = page;
    _lastAccessed[pageIndex] = DateTime.now();
    _loadingPages.remove(pageIndex);
  }

  /// Menandai halaman sedang loading
  void setLoading(int pageIndex, bool loading) {
    if (loading) {
      _loadingPages.add(pageIndex);
    } else {
      _loadingPages.remove(pageIndex);
    }
  }

  /// Membersihkan cache untuk halaman yang tidak sering diakses
  void cleanupCache({int maxAge = 30}) {
    final now = DateTime.now();
    final toRemove = <int>[];
    
    _lastAccessed.forEach((pageIndex, lastAccess) {
      if (now.difference(lastAccess).inMinutes > maxAge) {
        toRemove.add(pageIndex);
      }
    });
    
    for (final pageIndex in toRemove) {
      _pageCache.remove(pageIndex);
      _lastAccessed.remove(pageIndex);
      _isHeavyPage.remove(pageIndex);
    }
  }

  /// Force refresh halaman (clear cache)
  void refreshPage(int pageIndex) {
    _pageCache.remove(pageIndex);
    _lastAccessed.remove(pageIndex);
    _loadingPages.remove(pageIndex);
  }

  /// Mendapatkan statistik cache
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_pages': _pageCache.length,
      'loading_pages': _loadingPages.length,
      'heavy_pages': _isHeavyPage.length,
      'last_cleanup': DateTime.now().toIso8601String(),
    };
  }
}
