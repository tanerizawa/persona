import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../domain/usecases/mood_tracking_usecases.dart';
import '../../domain/entities/mood_entities.dart';
import '../widgets/mood_calendar_widget.dart';
import '../widgets/life_tree_widget.dart';

class GrowthPage extends StatefulWidget {
  const GrowthPage({super.key});

  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late MoodTrackingUseCases _moodTracking;
  int _currentMood = 7;
  List<MoodEntry> _recentMoods = [];
  MoodAnalytics? _moodAnalytics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _moodTracking = getIt<MoodTrackingUseCases>();
    _loadMoodData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMoodData() async {
    setState(() => _isLoading = true);
    try {
      final recentMoods = await _moodTracking.getRecentMoodEntries(limit: 7);
      final analytics = await _moodTracking.getMoodAnalytics();
      
      if (mounted) {
        setState(() {
          _recentMoods = recentMoods;
          _moodAnalytics = analytics;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading mood data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveMood(int moodLevel, {String? note}) async {
    try {
      await _moodTracking.logMood(
        moodLevel: moodLevel,
        note: note,
        tags: ['daily_tracking'],
      );
      
      setState(() => _currentMood = moodLevel);
      
      // Reload data
      await _loadMoodData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood ${_getMoodEmoji(moodLevel)} berhasil disimpan!'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving mood: $e')),
        );
      }
    }
  }

  String _getMoodEmoji(int moodLevel) {
    switch (moodLevel) {
      case 1:
      case 2:
        return '😢';
      case 3:
      case 4:
        return '😞';
      case 5:
      case 6:
        return '😐';
      case 7:
      case 8:
        return '😊';
      case 9:
      case 10:
        return '😄';
      default:
        return '😐';
    }
  }

  String _getMoodLabel(int moodLevel) {
    switch (moodLevel) {
      case 1:
      case 2:
        return 'Sangat Sedih';
      case 3:
      case 4:
        return 'Sedih';
      case 5:
      case 6:
        return 'Netral';
      case 7:
      case 8:
        return 'Senang';
      case 9:
      case 10:
        return 'Sangat Senang';
      default:
        return 'Netral';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Symbols.mood),
                  text: 'Mood',
                ),
                Tab(
                  icon: Icon(Symbols.calendar_month),
                  text: 'Kalender',
                ),
                Tab(
                  icon: Icon(Symbols.park),
                  text: 'Pohon Kehidupan',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMoodTrackerTab(),
                _buildCalendarTab(),
                _buildLifeTreeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTrackerTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Tracker',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Current Mood Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bagaimana perasaan Anda hari ini?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Mood Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final moodLevel = index * 2 + 2; // 2, 4, 6, 8, 10
                      final isSelected = _currentMood >= moodLevel - 1 && _currentMood <= moodLevel + 1;
                      
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: GestureDetector(
                            onTap: () => _saveMood(moodLevel),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                border: isSelected
                                    ? Border.all(color: Theme.of(context).primaryColor)
                                    : Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _getMoodEmoji(moodLevel),
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getMoodLabel(moodLevel),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isSelected 
                                          ? Theme.of(context).primaryColor 
                                          : null,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Analytics Card
          if (_moodAnalytics != null) _buildAnalyticsCard(),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Recent Moods
          if (_recentMoods.isNotEmpty) _buildRecentMoodsCard(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    final analytics = _moodAnalytics!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analisis Mood',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Rata-rata',
                    '${analytics.averageMood.toStringAsFixed(1)}/10',
                    _getMoodEmoji(analytics.averageMood.round()),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Entry',
                    '${analytics.totalEntries}',
                    '📊',
                  ),
                ),
              ],
            ),
            
            if (analytics.trends.isNotEmpty) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              ...analytics.trends.map((trend) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: trend.trendDirection > 0 
                        ? Colors.green.withValues(alpha: 0.1)
                        : trend.trendDirection < 0
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildRecentMoodsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Terakhir',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            ...(_recentMoods.take(5).map((mood) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    mood.moodEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mood.moodDescription,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (mood.note != null && mood.note!.isNotEmpty)
                          Text(
                            mood.note!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(mood.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ))),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hari ini';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  Widget _buildCalendarTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: MoodCalendarWidget(),
    );
  }

  Widget _buildLifeTreeTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: LifeTreeWidget(),
    );
  }
}
