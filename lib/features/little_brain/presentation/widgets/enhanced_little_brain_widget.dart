import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/background_sync_service.dart';
import '../../domain/usecases/little_brain_local_usecases.dart';
import '../../domain/entities/memory_entities.dart';
import '../../../../core/injection/injection.dart';
import 'minimal_sync_widget.dart';

class EnhancedLittleBrainWidget extends StatefulWidget {
  const EnhancedLittleBrainWidget({super.key});

  @override
  State<EnhancedLittleBrainWidget> createState() => _EnhancedLittleBrainWidgetState();
}

class _EnhancedLittleBrainWidgetState extends State<EnhancedLittleBrainWidget> 
    with TickerProviderStateMixin {
  SyncStatus? _syncStatus;
  bool _isLoading = false;
  PersonalityProfile? _personalityProfile;
  Map<String, dynamic>? _memoryStats;
  List<Memory>? _recentMemories;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Use cases
  late final GetPersonalityProfileLocalUseCase _getPersonalityProfile;
  late final GetMemoryStatisticsUseCase _getMemoryStats;
  late final ClearAllLocalDataUseCase _clearData;
  late final BackgroundSyncService _syncService;
  late final GetRelevantMemoriesLocalUseCase _getRecentMemories;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _loadData();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  void _initializeServices() {
    _getPersonalityProfile = getIt<GetPersonalityProfileLocalUseCase>();
    _getMemoryStats = getIt<GetMemoryStatisticsUseCase>();
    _clearData = getIt<ClearAllLocalDataUseCase>();
    _syncService = getIt<BackgroundSyncService>();
    _getRecentMemories = getIt<GetRelevantMemoriesLocalUseCase>();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _getPersonalityProfile.call();
      final stats = await _getMemoryStats.call();
      final status = await _syncService.getSyncStatus();
      final recent = await _getRecentMemories.call('recent activity', limit: 5);
      
      setState(() {
        _personalityProfile = profile;
        _memoryStats = stats;
        _syncStatus = status;
        _recentMemories = recent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.purple.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (_isLoading) 
                _buildLoadingState()
              else ...[
                _buildSyncStatus(),
                const SizedBox(height: 16),
                _buildMemoryStats(),
                const SizedBox(height: 16),
                _buildPersonalityOverview(),
                const SizedBox(height: 16),
                _buildRecentMemories(),
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3 * _pulseAnimation.value),
                    blurRadius: 20 * _pulseAnimation.value,
                    spreadRadius: 5 * _pulseAnimation.value,
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology,
                size: 32,
                color: Colors.purple,
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🧠 Little Brain',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                'Local AI Memory System',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Refresh Data',
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Little Brain data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    final status = _syncStatus;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            status?.syncNeeded == false ? Icons.cloud_done : Icons.cloud_off,
            color: status?.syncNeeded == false ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync Status',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  status?.statusMessage ?? 'Local-first mode (no sync needed)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (status?.shouldShowSyncButton == true)
            TextButton(
              onPressed: _forceSync,
              child: const Text('Sync Now'),
            ),
        ],
      ),
    );
  }

  Widget _buildMemoryStats() {
    final stats = _memoryStats;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Memory Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Memories',
                  '${stats['memory_count'] ?? 0}',
                  Icons.memory,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Avg Emotion',
                  '${((stats['average_emotional_weight'] ?? 0.5) * 100).toInt()}%',
                  Icons.favorite,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Sources',
                  '${stats['unique_sources'] ?? 0}',
                  Icons.source,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Contexts',
                  '${stats['unique_contexts'] ?? 0}',
                  Icons.category,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityOverview() {
    final profile = _personalityProfile;
    if (profile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personality Profile',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...profile.traits.entries.take(3).map((trait) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTraitName(trait.key),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${(trait.value * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
          if (profile.interests.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Top Interests: ${profile.interests.take(3).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentMemories() {
    final memories = _recentMemories;
    if (memories == null || memories.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...memories.take(3).map((memory) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getEmotionColor(memory.emotionalWeight),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      memory.content.length > 60 
                          ? '${memory.content.substring(0, 60)}...'
                          : memory.content,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openDashboard,
                icon: const Icon(Icons.dashboard),
                label: const Text('Open Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showAdvancedOptions,
                icon: const Icon(Icons.settings),
                label: const Text('Advanced'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openMinimalSync,
            icon: const Icon(Icons.cloud_sync),
            label: const Text('Minimal Server Sync'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTraitName(String trait) {
    return trait.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Color _getTraitColor(double value) {
    if (value > 0.7) return Colors.green;
    if (value > 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getEmotionColor(double emotion) {
    if (emotion > 0.6) return Colors.green;
    if (emotion > 0.4) return Colors.yellow;
    return Colors.red;
  }

  void _forceSync() async {
    try {
      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);
      
      final result = await _syncService.syncWhenOptimal();
      final newStatus = await _syncService.getSyncStatus();
      
      setState(() {
        _syncStatus = newStatus;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  void _openDashboard() {
    Navigator.pushNamed(context, '/little-brain-dashboard');
  }

  void _openMinimalSync() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Minimal Server Sync',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: MinimalSyncWidget(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvancedOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAdvancedOptionsSheet(),
    );
  }

  Widget _buildAdvancedOptionsSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Advanced Options',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Export Data'),
            subtitle: const Text('Export your Little Brain data'),
            onTap: _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Create Backup'),
            subtitle: const Text('Create encrypted backup'),
            onTap: _createBackup,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all local memories'),
            onTap: _confirmClearData,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _exportData() {
    Navigator.pop(context);
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon!')),
    );
  }

  void _createBackup() {
    Navigator.pop(context);
    // TODO: Implement backup creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup feature coming soon!')),
    );
  }

  void _confirmClearData() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your Little Brain memories and personality data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      HapticFeedback.heavyImpact();
      setState(() => _isLoading = true);
      
      await _clearData.call();
      
      setState(() {
        _personalityProfile = null;
        _memoryStats = null;
        _recentMemories = null;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear data: $e')),
        );
      }
    }
  }
}
