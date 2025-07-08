import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../core/services/sync_scheduler_service.dart';
import '../../../../injection_container.dart';

/// Widget that displays sync status and provides manual sync controls
class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  late final SyncSchedulerService _syncScheduler;
  SyncStats? _syncStats;
  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _syncScheduler = getIt<SyncSchedulerService>();
    _loadSyncStats();
    
    // Start the sync scheduler
    _syncScheduler.startScheduler();
    
    // Refresh stats periodically
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadSyncStats(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSyncStats() async {
    final stats = await _syncScheduler.getSyncStats();
    if (mounted) {
      setState(() {
        _syncStats = stats;
      });
    }
  }

  Future<void> _performManualSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _syncScheduler.forceSyncNow();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success 
                  ? 'Sync completed successfully' 
                  : 'Sync failed: ${result.message}',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }

      await _loadSyncStats();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) {
      return 'Now';
    }
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_syncStats == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final timeUntilNext = _syncStats!.nextSyncTime.difference(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync,
                  color: _syncStats!.isSchedulerRunning ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Background Sync',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: _performManualSync,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Manual sync',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sync status
            Row(
              children: [
                Icon(
                  _syncStats!.isSchedulerRunning ? Icons.check_circle : Icons.error,
                  color: _syncStats!.isSchedulerRunning ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _syncStats!.isSchedulerRunning ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: _syncStats!.isSchedulerRunning ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Last sync time
            Row(
              children: [
                const Icon(Icons.history, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Last sync: ${_formatDateTime(_syncStats!.lastSyncTime)}'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Next sync time
            Row(
              children: [
                const Icon(Icons.schedule, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Next sync: ${_formatDuration(timeUntilNext)}'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Sync interval
            Row(
              children: [
                const Icon(Icons.timer, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Interval: ${_syncStats!.syncIntervalMinutes} minutes'),
              ],
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _performManualSync,
                icon: const Icon(Icons.cloud_sync),
                label: const Text('Sync Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
