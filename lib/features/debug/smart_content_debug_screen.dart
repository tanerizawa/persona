import 'package:flutter/material.dart';
import '../../../injection_container.dart';
import '../home/domain/usecases/smart_content_manager.dart';

/// Debug screen untuk testing SmartContentManager improvements
class SmartContentDebugScreen extends StatefulWidget {
  const SmartContentDebugScreen({super.key});

  @override
  State<SmartContentDebugScreen> createState() => _SmartContentDebugScreenState();
}

class _SmartContentDebugScreenState extends State<SmartContentDebugScreen> {
  late SmartContentManager _smartContentManager;
  Map<String, dynamic>? _healthData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _smartContentManager = getIt<SmartContentManager>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Content Debug'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Analytics Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Analytics & Monitoring',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _printAnalytics,
                            icon: const Icon(Icons.analytics),
                            label: const Text('Print Analytics'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _getSystemHealth,
                            icon: const Icon(Icons.health_and_safety),
                            label: const Text('Health Check'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _warmUpCache,
                            icon: const Icon(Icons.rocket_launch),
                            label: const Text('Warm Cache'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testContentGeneration,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Test Generation'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Health Data Section
            if (_healthData != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏥 System Health',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ..._healthData!.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                _formatValue(entry.value),
                                style: TextStyle(
                                  color: _getHealthColor(entry.key, entry.value),
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
            
            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            
            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Instructions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Warm Cache: Preload content untuk faster loading\n'
                      '2. Test Generation: Generate content dan lihat performance\n'
                      '3. Health Check: Check system health dan metrics\n'
                      '4. Print Analytics: Print detailed analytics ke console\n'
                      '\n'
                      'Perhatikan console logs untuk detailed information.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printAnalytics() async {
    setState(() => _isLoading = true);
    try {
      await _smartContentManager.printAnalyticsSummary();
      _showSnackBar('Analytics printed to console', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getSystemHealth() async {
    setState(() => _isLoading = true);
    try {
      final health = await _smartContentManager.getSystemHealth();
      setState(() => _healthData = health);
      _showSnackBar('Health check completed', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _warmUpCache() async {
    setState(() => _isLoading = true);
    try {
      await _smartContentManager.warmUpCache();
      _showSnackBar('Cache warmed up successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testContentGeneration() async {
    setState(() => _isLoading = true);
    try {
      final content = await _smartContentManager.getSmartContent();
      _showSnackBar('Generated ${content.length} items', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(1);
    } else if (value is String && value.contains('T')) {
      // Format timestamp
      try {
        final dt = DateTime.parse(value);
        return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return value.toString();
      }
    }
    return value.toString();
  }

  Color _getHealthColor(String key, dynamic value) {
    if (key == 'status') {
      return value == 'healthy' ? Colors.green : Colors.red;
    } else if (key.contains('rate') && value is double) {
      if (value > 80) return Colors.green;
      if (value > 50) return Colors.orange;
      return Colors.red;
    } else if (key.contains('time') && value is double) {
      if (value < 100) return Colors.green;
      if (value < 300) return Colors.orange;
      return Colors.red;
    }
    return Colors.black87;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
