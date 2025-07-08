import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../chat/presentation/pages/chat_page.dart';
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

  final List<Widget> _pages = [
    const AIHomeTabView(),
    const ChatPage(),
    const GrowthPage(),
    const PsychologyPage(),
  ];

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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: _bottomNavItems,
      ),
    );
  }
}
