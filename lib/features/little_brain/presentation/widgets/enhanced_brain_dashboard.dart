import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/little_brain_performance_monitor.dart';
import '../../data/repositories/little_brain_local_repository.dart';
import '../../data/services/personality_intelligence.dart';
import '../../data/services/local_ai_service.dart';
import '../../data/services/tflite_local_ai_service.dart';
import '../../data/services/growing_brain_service.dart';

/// Enhanced Dashboard untuk monitoring dan optimasi Little Brain performance
class EnhancedLittleBrainDashboard extends StatefulWidget {
  const EnhancedLittleBrainDashboard({super.key});

  @override
  State<EnhancedLittleBrainDashboard> createState() => _EnhancedLittleBrainDashboardState();
}

class _EnhancedLittleBrainDashboardState extends State<EnhancedLittleBrainDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final LittleBrainLocalRepository _repository;
  late final LocalAIService _localAIService;
  late final TFLiteLocalAIService _tfliteService;
  late final GrowingBrainService _growingBrainService;
  
  Map<String, dynamic> _performanceMetrics = {};
  Map<String, dynamic> _memoryStats = {};
  PersonalityInsights? _personalityInsights;
  BrainInsights? _brainInsights;
  Map<String, dynamic> _modelStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Get services dari dependency injection
    _localAIService = GetIt.instance<LocalAIService>();
    _tfliteService = GetIt.instance<TFLiteLocalAIService>();
    _growingBrainService = GetIt.instance<GrowingBrainService>();
    _repository = GetIt.instance<LittleBrainLocalRepository>();
    
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
      
      // Load brain insights
      _brainInsights = await _growingBrainService.getBrainInsights();
      
      // Load model status
      _modelStatus = _tfliteService.getModelStatus();
      
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
        title: const Text('Enhanced Little Brain Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Performance'),
            Tab(icon: Icon(Icons.memory), text: 'Memory'),
            Tab(icon: Icon(Icons.psychology), text: 'Personality'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'Brain Growth'),
            Tab(icon: Icon(Icons.settings), text: 'AI Models'),
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
                _buildBrainGrowthTab(),
                _buildAIModelsTab(),
              ],
            ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          if (_performanceMetrics.isNotEmpty) ...[
            for (final entry in _performanceMetrics.entries)
              _buildPerformanceCard(entry.key, entry.value as Map<String, dynamic>),
          ] else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No performance data available yet'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(String operation, Map<String, dynamic> metrics) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              operation.replaceAll('_', ' ').toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Operations: ${metrics['operation_count'] ?? 0}'),
                      Text('Avg Duration: ${metrics['average_duration_ms'] ?? 0}ms'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Duration: ${metrics['last_duration_ms'] ?? 0}ms'),
                      Text('Total Time: ${metrics['total_duration_ms'] ?? 0}ms'),
                    ],
                  ),
                ),
              ],
            ),
            if (metrics['average_duration_ms'] != null)
              LinearProgressIndicator(
                value: ((metrics['average_duration_ms'] as int) / 1000).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  (metrics['average_duration_ms'] as int) > 500 
                      ? Colors.red 
                      : (metrics['average_duration_ms'] as int) > 200 
                          ? Colors.orange 
                          : Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Memory Statistics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          if (_memoryStats.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Memory Overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Total Memories: ${_memoryStats['total_memories'] ?? 0}'),
                    Text('Unique Tags: ${_memoryStats['unique_tags'] ?? 0}'),
                    Text('Unique Contexts: ${_memoryStats['unique_contexts'] ?? 0}'),
                    Text('Average Emotional Weight: ${(_memoryStats['average_emotional_weight'] ?? 0.0).toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
          ] else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No memory data available yet'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personality Analysis',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          if (_personalityInsights != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personality Traits',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._personalityInsights!.traits.entries.map((trait) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatTraitName(trait.key)),
                                Text('${(trait.value * 100).toInt()}%'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: trait.value,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getTraitColor(trait.value),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insights Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_personalityInsights!.summary),
                  ],
                ),
              ),
            ),
          ] else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No personality data available yet'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBrainGrowthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Brain Development',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          if (_brainInsights != null) ...[
            // Development Stage Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStageIcon(_brainInsights!.developmentStage),
                          size: 32,
                          color: _getStageColor(_brainInsights!.developmentStage),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Development Stage',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              _brainInsights!.developmentStage.toUpperCase(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getStageColor(_brainInsights!.developmentStage),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Progress: ${(_brainInsights!.developmentProgress * 100).toInt()}%'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _brainInsights!.developmentProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStageColor(_brainInsights!.developmentStage),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Neural Connections Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Neural Network',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Connections: ${_brainInsights!.neuralConnections} / ${_brainInsights!.maxConnections}'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _brainInsights!.neuralConnections / _brainInsights!.maxConnections,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cognitive Abilities Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cognitive Abilities',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._brainInsights!.cognitiveAbilities.entries.map((ability) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatAbilityName(ability.key)),
                                Text('${(ability.value * 100).toInt()}%'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: ability.value,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getAbilityColor(ability.value),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Milestones Card
            if (_brainInsights!.milestones.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Development Milestones',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._brainInsights!.milestones.take(5).map((milestone) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, 
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(_formatMilestone(milestone)),
                            ],
                          ),
                        );
                      }),
                      if (_brainInsights!.milestones.length > 5)
                        Text('... and ${_brainInsights!.milestones.length - 5} more'),
                    ],
                  ),
                ),
              ),
          ] else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Brain development data loading...'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAIModelsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Models Status',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // TensorFlow Lite Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TensorFlow Lite Enhanced AI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow('Models Loaded', _modelStatus['models_loaded'] ?? false),
                  _buildStatusRow('TFLite Available', _modelStatus['tflite_available'] ?? false),
                  _buildStatusRow('Enhanced Processing', _modelStatus['enhanced_processing'] ?? false),
                  _buildStatusRow('Vocabulary Size', '${_modelStatus['vocabulary_size'] ?? 0} words'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Model Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Model Components',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow('Sentiment Model', _modelStatus['sentiment_model_available'] ?? false),
                  _buildStatusRow('Personality Model', _modelStatus['personality_model_available'] ?? false),
                  _buildStatusRow('Intent Model', _modelStatus['intent_model_available'] ?? false),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await _tfliteService.initializeEnhanced();
                      await _loadDashboardData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('AI Service reinitialized')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Initialization failed: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reinitialize'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await _tfliteService.updateModels();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Model update checked')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Update failed: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Update Models'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          if (value is bool)
            Icon(
              value ? Icons.check_circle : Icons.cancel,
              color: value ? Colors.green : Colors.red,
              size: 16,
            )
          else
            Text(value.toString()),
        ],
      ),
    );
  }

  String _formatTraitName(String trait) {
    return trait.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatAbilityName(String ability) {
    return ability.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatMilestone(String milestone) {
    return milestone.replaceAll('_', ' ').split(' ').map((word) => 
        word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Color _getTraitColor(double value) {
    if (value > 0.7) return Colors.green;
    if (value > 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getAbilityColor(double value) {
    if (value > 0.8) return Colors.green;
    if (value > 0.5) return Colors.blue;
    if (value > 0.3) return Colors.orange;
    return Colors.red;
  }

  IconData _getStageIcon(String stage) {
    switch (stage) {
      case 'infant':
        return Icons.child_care;
      case 'child':
        return Icons.school;
      case 'adolescent':
        return Icons.psychology;
      case 'adult':
        return Icons.person;
      case 'mature':
        return Icons.auto_awesome;
      default:
        return Icons.help;
    }
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'infant':
        return Colors.pink;
      case 'child':
        return Colors.blue;
      case 'adolescent':
        return Colors.purple;
      case 'adult':
        return Colors.green;
      case 'mature':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
