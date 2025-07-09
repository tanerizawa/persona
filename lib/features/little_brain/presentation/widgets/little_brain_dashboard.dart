import 'package:flutter/material.dart';
import '../../../../core/services/little_brain_performance_monitor.dart';
import '../../data/repositories/little_brain_local_repository.dart';
import '../../data/services/personality_intelligence.dart';
import '../../data/services/local_ai_service.dart';

/// Dashboard untuk monitoring dan optimasi Little Brain performance
class LittleBrainDashboard extends StatefulWidget {
  const LittleBrainDashboard({super.key});

  @override
  State<LittleBrainDashboard> createState() => _LittleBrainDashboardState();
}

class _LittleBrainDashboardState extends State<LittleBrainDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final LittleBrainLocalRepository _repository;
  late final LocalAIService _localAIService;
  
  Map<String, dynamic> _performanceMetrics = {};
  Map<String, dynamic> _memoryStats = {};
  PersonalityInsights? _personalityInsights;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _localAIService = LocalAIService();
    _repository = LittleBrainLocalRepository(_localAIService);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load performance metrics
      _performanceMetrics = LittleBrainPerformanceMonitor.getMetrics();
      
      // Load memory statistics
      _memoryStats = await _repository.getMemoryStatistics();
      
      // Load personality insights
      final allMemories = await _repository.getAllMemories();
      if (allMemories.isNotEmpty) {
        final traits = PersonalityIntelligence.analyzeTraits(allMemories);
        _personalityInsights = PersonalityIntelligence.generateInsights(traits, allMemories);
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Little Brain Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.speed), text: 'Performance'),
            Tab(icon: Icon(Icons.memory), text: 'Memory'),
            Tab(icon: Icon(Icons.psychology), text: 'Personality'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPerformanceTab(),
                _buildMemoryTab(),
                _buildPersonalityTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  Widget _buildPerformanceTab() {
    final overallScore = LittleBrainPerformanceMonitor.getOverallPerformanceScore();
    final memoryEfficiency = LittleBrainPerformanceMonitor.getMemoryEfficiency();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Performance Score
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Overall Performance Score',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  CircularProgressIndicator(
                    value: overallScore,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getScoreColor(overallScore),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(overallScore * 100).toInt()}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _getScoreColor(overallScore),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Performance Metrics
          Text(
            'Performance Metrics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          
          if (_performanceMetrics.isNotEmpty) ...[
            for (final entry in _performanceMetrics.entries)
              _buildMetricCard(entry.key, entry.value as Map<String, dynamic>),
          ] else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No performance data available yet'),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Memory Efficiency
          if (memoryEfficiency.isNotEmpty) ...[
            Text(
              'Memory Processing Efficiency',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final entry in memoryEfficiency.entries)
              _buildEfficiencyCard(entry.key, entry.value as Map<String, dynamic>),
          ],
        ],
      ),
    );
  }

  Widget _buildMemoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Memory Statistics
          Text(
            'Memory Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Memories',
                  _memoryStats['total_memories']?.toString() ?? '0',
                  Icons.storage,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Avg Emotional Weight',
                  (_memoryStats['avg_emotional_weight'] ?? 0.0).toStringAsFixed(2),
                  Icons.favorite,
                  Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Most Common Contexts
          if (_memoryStats['most_common_contexts'] != null) ...[
            Text(
              'Most Common Contexts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final context in _memoryStats['most_common_contexts'])
                      Chip(
                        label: Text(context['key']),
                        avatar: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            context['value'].toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Most Common Tags
          if (_memoryStats['most_common_tags'] != null) ...[
            Text(
              'Most Common Tags',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final tag in _memoryStats['most_common_tags'])
                      Chip(
                        label: Text(tag['key']),
                        backgroundColor: Colors.green[100],
                        avatar: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(
                            tag['value'].toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalityTab() {
    if (_personalityInsights == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No personality data available yet'),
            SizedBox(height: 8),
            Text('Start using the app to build your personality profile'),
          ],
        ),
      );
    }

    final insights = _personalityInsights!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personality Type
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.psychology, size: 48, color: Colors.purple),
                  const SizedBox(height: 8),
                  Text(
                    insights.personalityType,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on ${insights.memoryCount} memories',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Big Five Traits
          Text(
            'Personality Traits',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          
          for (final entry in insights.traits.entries)
            _buildTraitBar(entry.key, entry.value),
          
          const SizedBox(height: 16),
          
          // Strengths and Growth Areas
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strengths',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final strength in insights.strengths)
                      Card(
                        color: Colors.green[50],
                        child: ListTile(
                          leading: const Icon(Icons.star, color: Colors.green),
                          title: Text(strength),
                          dense: true,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Growth Areas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final growthArea in insights.growthAreas)
                      Card(
                        color: Colors.orange[50],
                        child: ListTile(
                          leading: const Icon(Icons.trending_up, color: Colors.orange),
                          title: Text(growthArea),
                          dense: true,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optimization Insights',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // System Health
          _buildInsightCard(
            'System Health',
            _getSystemHealthInsight(),
            Icons.health_and_safety,
            Colors.green,
          ),
          
          // Performance Recommendations
          _buildInsightCard(
            'Performance Recommendations',
            _getPerformanceRecommendations(),
            Icons.speed,
            Colors.blue,
          ),
          
          // Memory Optimization
          _buildInsightCard(
            'Memory Optimization',
            _getMemoryOptimizationInsights(),
            Icons.memory,
            Colors.purple,
          ),
          
          // Personality Development
          if (_personalityInsights != null)
            _buildInsightCard(
              'Personality Development',
              _personalityInsights!.recommendations.join('\n\n'),
              Icons.psychology,
              Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String operation, Map<String, dynamic> metrics) {
    final avgDuration = metrics['average_duration_ms'] ?? 0;
    final threshold = metrics['threshold_ms'] ?? 1000;
    final withinThresholdRatio = metrics['within_threshold_ratio'] ?? 0.0;
    
    return Card(
      child: ListTile(
        title: Text(operation.replaceAll('_', ' ').toUpperCase()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avg Duration: ${avgDuration}ms (Threshold: ${threshold}ms)'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: withinThresholdRatio,
              backgroundColor: Colors.red[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                withinThresholdRatio > 0.8 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        trailing: CircleAvatar(
          backgroundColor: withinThresholdRatio > 0.8 ? Colors.green : Colors.orange,
          child: Text(
            '${(withinThresholdRatio * 100).toInt()}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildEfficiencyCard(String operation, Map<String, dynamic> efficiency) {
    final score = efficiency['efficiency_score'] ?? 0.0;
    final avgDuration = efficiency['average_duration'] ?? 0;
    final opsPerMinute = efficiency['operations_per_minute'] ?? 0.0;
    
    return Card(
      child: ListTile(
        title: Text(operation.replaceAll('_', ' ').toUpperCase()),
        subtitle: Text('Avg: ${avgDuration}ms | ${opsPerMinute.toStringAsFixed(1)} ops/min'),
        trailing: CircularProgressIndicator(
          value: score,
          strokeWidth: 4,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraitBar(String trait, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trait.toUpperCase(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getTraitColor(trait)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String content, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score > 0.8) return Colors.green;
    if (score > 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getTraitColor(String trait) {
    const colors = {
      'openness': Colors.purple,
      'conscientiousness': Colors.blue,
      'extraversion': Colors.orange,
      'agreeableness': Colors.green,
      'neuroticism': Colors.red,
    };
    return colors[trait] ?? Colors.grey;
  }

  String _getSystemHealthInsight() {
    final overallScore = LittleBrainPerformanceMonitor.getOverallPerformanceScore();
    
    if (overallScore > 0.8) {
      return 'System is performing excellently. All operations are within optimal thresholds.';
    } else if (overallScore > 0.6) {
      return 'System is performing well. Some operations could be optimized for better performance.';
    } else {
      return 'System performance needs attention. Several operations are exceeding recommended thresholds.';
    }
  }

  String _getPerformanceRecommendations() {
    final recommendations = <String>[];
    
    for (final entry in _performanceMetrics.entries) {
      final metrics = entry.value as Map<String, dynamic>;
      final withinThresholdRatio = metrics['within_threshold_ratio'] ?? 0.0;
      
      if (withinThresholdRatio < 0.7) {
        recommendations.add('Optimize ${entry.key.replaceAll('_', ' ')} operation');
      }
    }
    
    if (recommendations.isEmpty) {
      return 'All operations are performing within acceptable parameters. Keep up the good work!';
    }
    
    return recommendations.join('\n');
  }

  String _getMemoryOptimizationInsights() {
    final totalMemories = _memoryStats['total_memories'] ?? 0;
    
    if (totalMemories < 10) {
      return 'System is learning about you. Continue using the app to build a comprehensive personality model.';
    } else if (totalMemories < 100) {
      return 'Good memory accumulation. The system is building a solid understanding of your patterns and preferences.';
    } else {
      return 'Rich memory database established. Consider periodic cleanup of old or irrelevant memories to maintain optimal performance.';
    }
  }
}
