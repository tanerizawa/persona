import 'package:flutter/material.dart';
import '../../data/services/background_sync_service.dart';
import '../../domain/usecases/little_brain_local_usecases.dart';
import '../../domain/entities/memory_entities.dart';
import '../../../../core/injection/injection.dart';

class LittleBrainLocalWidget extends StatefulWidget {
  const LittleBrainLocalWidget({super.key});

  @override
  State<LittleBrainLocalWidget> createState() => _LittleBrainLocalWidgetState();
}

class _LittleBrainLocalWidgetState extends State<LittleBrainLocalWidget> {
  SyncStatus? _syncStatus;
  bool _isLoading = false;
  PersonalityProfile? _personalityProfile;
  Map<String, dynamic>? _memoryStats;

  // Use cases
  late final GetPersonalityProfileLocalUseCase _getPersonalityProfile;
  late final GetMemoryStatisticsUseCase _getMemoryStats;
  late final ClearAllLocalDataUseCase _clearData;
  late final BackgroundSyncService _syncService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadData();
  }

  void _initializeServices() {
    _getPersonalityProfile = getIt<GetPersonalityProfileLocalUseCase>();
    _getMemoryStats = getIt<GetMemoryStatisticsUseCase>();
    _clearData = getIt<ClearAllLocalDataUseCase>();
    _syncService = getIt<BackgroundSyncService>();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _getPersonalityProfile.call();
      final stats = await _getMemoryStats.call();
      final status = await _syncService.getSyncStatus();
      
      setState(() {
        _personalityProfile = profile;
        _memoryStats = stats;
        _syncStatus = status;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error loading Little Brain data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Little Brain'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSyncStatus(),
                  const SizedBox(height: 24),
                  _buildPersonalityProfile(),
                  const SizedBox(height: 24),
                  _buildMemoryStatistics(),
                  const SizedBox(height: 24),
                  _buildActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
                children: [
                  Icon(
                    _syncStatus?.syncNeeded == false
                        ? Icons.check_circle
                        : _syncStatus?.isOptimalConditions == true
                            ? Icons.sync
                            : Icons.error,
                    color: _syncStatus?.syncNeeded == false
                        ? Colors.green
                        : _syncStatus?.isOptimalConditions == true
                            ? Colors.orange
                            : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_syncStatus?.statusMessage ?? 'Unknown status'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalityProfile() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personality Profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_personalityProfile != null) ...[
              _buildTraitItem('Communication Style', 
                  _personalityProfile!.traits['communicationStyle']?.toString() ?? 'Not analyzed'),
              _buildTraitItem('Interests', 
                  _personalityProfile!.traits['interests']?.toString() ?? 'None'),
              _buildTraitItem('Emotional Patterns', 
                  _personalityProfile!.traits['emotionalPatterns']?.toString() ?? 'Not analyzed'),
              _buildTraitItem('Learning Style', 
                  _personalityProfile!.traits['learningStyle']?.toString() ?? 'Not analyzed'),
            ] else
              const Text('No personality data available'),
          ],
        ),
      ),
    );
  }

  Widget _buildTraitItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Memory Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_memoryStats != null) ...[
              _buildStatItem('Total Memories', '${_memoryStats!['total_memories'] ?? 0}'),
              _buildStatItem('Memory Sources', '${_memoryStats!['sources']?.length ?? 0}'),
              _buildStatItem('Avg Emotional Weight', 
                  '${(_memoryStats!['avg_emotional_weight'] ?? 0.0).toStringAsFixed(2)}'),
              _buildStatItem('Days with Memories', '${_memoryStats!['days_with_memories'] ?? 0}'),
            ] else
              const Text('No memory statistics available'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _syncData,
                icon: const Icon(Icons.sync),
                label: const Text('Sync Data'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _clearAllData,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear All Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _syncData() async {
    try {
      await _syncService.syncWhenOptimal();
      _loadData(); // Reload data after sync
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data synced successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  void _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to clear all local data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _clearData.call();
        _loadData(); // Reload data after clearing
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All data cleared successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear data: $e')),
          );
        }
      }
    }
  }
}
