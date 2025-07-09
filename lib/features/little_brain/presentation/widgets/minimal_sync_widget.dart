import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/services/minimal_sync_service.dart';
import '../../data/repositories/little_brain_local_repository.dart';
import '../../data/models/hive_models.dart';

class MinimalSyncWidget extends StatefulWidget {
  const MinimalSyncWidget({Key? key}) : super(key: key);

  @override
  State<MinimalSyncWidget> createState() => _MinimalSyncWidgetState();
}

class _MinimalSyncWidgetState extends State<MinimalSyncWidget> {
  final MinimalSyncService _syncService = GetIt.instance<MinimalSyncService>();
  final LittleBrainLocalRepository _localRepo = GetIt.instance<LittleBrainLocalRepository>();

  bool _isLoading = false;
  Map<String, dynamic>? _syncStats;
  String? _statusMessage;
  Color _statusColor = Colors.grey;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSyncStatistics();
  }

  Future<void> _loadSyncStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _syncService.getSyncStatistics();
      setState(() {
        _syncStats = stats;
        _updateStatus();
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading sync statistics: $e';
        _statusColor = Colors.red;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateStatus() {
    if (_syncStats == null) return;

    final isAuthenticated = _syncStats!['is_authenticated'] ?? false;
    final serverHealthy = _syncStats!['server_healthy'] ?? false;
    final lastSync = _syncStats!['last_sync_memories'];

    if (!isAuthenticated) {
      _statusMessage = 'Not authenticated';
      _statusColor = Colors.orange;
    } else if (!serverHealthy) {
      _statusMessage = 'Server not available';
      _statusColor = Colors.red;
    } else if (lastSync == null) {
      _statusMessage = 'Ready to sync';
      _statusColor = Colors.blue;
    } else {
      final syncTime = DateTime.parse(lastSync);
      final diff = DateTime.now().difference(syncTime);
      
      if (diff.inHours < 1) {
        _statusMessage = 'Synced ${diff.inMinutes}m ago';
        _statusColor = Colors.green;
      } else if (diff.inDays < 1) {
        _statusMessage = 'Synced ${diff.inHours}h ago';
        _statusColor = Colors.green;
      } else {
        _statusMessage = 'Synced ${diff.inDays}d ago';
        _statusColor = Colors.orange;
      }
    }
  }

  Future<void> _registerUser() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please enter username and password', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _syncService.registerUser(
        _usernameController.text,
        _passwordController.text,
      );

      if (result.isSuccess) {
        _showSnackBar('Registration successful!', Colors.green);
        _usernameController.clear();
        _passwordController.clear();
        await _loadSyncStatistics();
      } else {
        _showSnackBar('Registration failed: ${result.message}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Registration error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginUser() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please enter username and password', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _syncService.loginUser(
        _usernameController.text,
        _passwordController.text,
      );

      if (result.isSuccess) {
        _showSnackBar('Login successful!', Colors.green);
        _usernameController.clear();
        _passwordController.clear();
        await _loadSyncStatistics();
      } else {
        _showSnackBar('Login failed: ${result.message}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Login error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performFullSync() async {
    setState(() => _isLoading = true);
    try {
      // Get local data and convert to Hive format
      final memories = await _localRepo.getAllMemories();
      final profile = await _localRepo.getPersonalityProfile();

      // Convert Memory entities to HiveMemory for sync
      final hiveMemories = memories.map((memory) => HiveMemory(
        id: memory.id,
        content: memory.content,
        tags: memory.tags,
        contexts: memory.contexts,
        emotionalWeight: memory.emotionalWeight,
        timestamp: memory.timestamp,
        source: memory.source,
        metadata: memory.metadata,
      )).toList();

      // Convert PersonalityProfile to HivePersonalityProfile for sync
      HivePersonalityProfile? hiveProfile;
      if (profile != null) {
        hiveProfile = HivePersonalityProfile(
          userId: profile.userId,
          traits: profile.traits,
          interests: profile.interests,
          values: profile.values,
          communicationPatterns: profile.communicationPatterns,
          lastUpdated: profile.lastUpdated,
          memoryCount: profile.memoryCount,
        );
      }

      final result = await _syncService.performFullSync(hiveMemories, hiveProfile);

      if (result.isSuccess) {
        final data = result.data as Map<String, dynamic>;
        final pushedCount = data['pushed_memories'] ?? 0;
        final pulledCount = data['pulled_memories'] ?? 0;
        
        _showSnackBar('Sync complete: ${pushedCount} pushed, ${pulledCount} pulled', Colors.green);
        await _loadSyncStatistics();
      } else {
        _showSnackBar('Sync failed: ${result.message}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Sync error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await _syncService.logout();
      _showSnackBar('Logged out successfully', Colors.blue);
      await _loadSyncStatistics();
    } catch (e) {
      _showSnackBar('Logout error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading sync status...'),
          ],
        ),
      );
    }

    final isAuthenticated = _syncStats?['is_authenticated'] ?? false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isAuthenticated ? Icons.cloud_done : Icons.cloud_off,
                  color: _statusColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusMessage ?? 'Unknown status',
                        style: TextStyle(color: _statusColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadSyncStatistics,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Authentication section
          if (!isAuthenticated) ...[
            Text(
              'Server Authentication',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loginUser,
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _registerUser,
                    child: const Text('Register'),
                  ),
                ),
              ],
            ),
          ],

          // Sync controls section
          if (isAuthenticated) ...[
            Text(
              'Sync Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _performFullSync,
                icon: const Icon(Icons.sync),
                label: const Text('Full Sync'),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Sync statistics
          if (_syncStats != null) ...[
            Text(
              'Sync Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Server Health', 
                    _syncStats!['server_healthy'] ? 'Online' : 'Offline',
                    _syncStats!['server_healthy'] ? Colors.green : Colors.red,
                  ),
                  const Divider(),
                  _buildInfoRow('Authentication', 
                    isAuthenticated ? 'Logged In' : 'Not Authenticated',
                    isAuthenticated ? Colors.green : Colors.orange,
                  ),
                  const Divider(),
                  _buildInfoRow('Device ID', 
                    _syncStats!['device_id'] ?? 'Unknown',
                    Colors.grey,
                  ),
                  const Divider(),
                  _buildInfoRow('Server URL', 
                    _syncStats!['server_url'] ?? 'Unknown',
                    Colors.grey,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Server info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Minimal Sync',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is an ultra-minimal sync server designed for Local-First Architecture. '
                  'Only essential data like memory counts and checksums are synced, '
                  'maintaining maximum privacy while enabling multi-device access.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
