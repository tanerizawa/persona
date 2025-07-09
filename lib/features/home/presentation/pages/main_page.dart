import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/lazy_page_loader.dart';
import '../../../../core/services/lazy_page_service.dart';
import '../../../../core/services/page_preload_service.dart';
import '../../../chat/presentation/pages/chat_page_imessage.dart';
import '../../../growth/presentation/pages/growth_page.dart';
import '../../../psychology/presentation/pages/psychology_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../widgets/ai_home_tab_view.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final PagePreloadService _preloadService = PagePreloadService();

  // Only home page is loaded initially
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    // Initialize pages with lazy loading
    _pages = [
      // Home page - always loaded (index 0)
      const AIHomeTabView(),
      
      // Chat page - lazy loaded (index 1)
      LazyPageLoader(
        pageIndex: 1,
        pageBuilder: () => const ChatPageiMessage(),
        isHeavyPage: true,
        loadingWidget: _buildPageLoadingWidget('Chat'),
      ),
      
      // Growth page - lazy loaded (index 2)  
      LazyPageLoader(
        pageIndex: 2,
        pageBuilder: () => const GrowthPage(),
        isHeavyPage: true,
        loadingWidget: _buildPageLoadingWidget('Growth'),
      ),
      
      // Psychology page - lazy loaded (index 3)
      LazyPageLoader(
        pageIndex: 3,
        pageBuilder: () => const PsychologyPage(),
        isHeavyPage: true,
        loadingWidget: _buildPageLoadingWidget('Psychology'),
      ),
    ];
  }

  Widget _buildPageLoadingWidget(String pageName) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$pageName - ${AppConstants.appName}'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat halaman...'),
            SizedBox(height: 8),
            Text(
              'Halaman akan tersimpan untuk akses yang lebih cepat',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Symbols.home),
      activeIcon: Icon(Symbols.home, fill: 1),
      label: AppStrings.homeTab,
    ),
    const BottomNavigationBarItem(
      icon: Icon(Symbols.chat),
      activeIcon: Icon(Symbols.chat, fill: 1),
      label: AppStrings.chatTab,
    ),
    const BottomNavigationBarItem(
      icon: Icon(Symbols.trending_up),
      activeIcon: Icon(Symbols.trending_up, fill: 1),
      label: AppStrings.growthTab,
    ),
    const BottomNavigationBarItem(
      icon: Icon(Symbols.psychology),
      activeIcon: Icon(Symbols.psychology, fill: 1),
      label: AppStrings.psychologyTab,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          // Cache cleanup button (debug mode)
          if (_isDebugMode()) 
            IconButton(
              onPressed: _showCacheDialog,
              icon: const Icon(Icons.cached),
              tooltip: 'Cache Management',
            ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Symbols.settings),
            tooltip: AppStrings.settingsTab,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          // Record page visit untuk analytics dan preloading
          await _preloadService.recordPageVisit(index);
          
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: _bottomNavItems,
      ),
    );
  }

  bool _isDebugMode() {
    bool debugMode = false;
    assert(debugMode = true);
    return debugMode;
  }

  void _showCacheDialog() {
    final lazyService = LazyPageService();
    final stats = lazyService.getCacheStats();
    final analytics = _preloadService.getNavigationAnalytics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache & Analytics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📦 Cache Stats:'),
              Text('  • Cached Pages: ${stats['cached_pages']}'),
              Text('  • Loading Pages: ${stats['loading_pages']}'), 
              Text('  • Heavy Pages: ${stats['heavy_pages']}'),
              const SizedBox(height: 12),
              Text('📊 Navigation Analytics:'),
              Text('  • Page Visits: ${analytics['page_visit_counts']}'),
              Text('  • Frequent Pages: ${analytics['frequently_accessed']}'),
              const SizedBox(height: 12),
              const Text(
                'Cache helps load pages faster. Analytics help predict which pages to preload.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              lazyService.cleanupCache(maxAge: 0); // Force cleanup all
              await _preloadService.clearAnalytics();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache and analytics cleared')),
                );
              }
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
