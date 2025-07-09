import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/offline_mode_service.dart';
import '../../injection_container.dart';

/// Widget untuk menampilkan status konektivitas dan mode offline
class ConnectivityStatusWidget extends StatefulWidget {
  final Widget child;
  final bool showStatusBar;
  
  const ConnectivityStatusWidget({
    super.key,
    required this.child,
    this.showStatusBar = true,
  });
  
  @override
  State<ConnectivityStatusWidget> createState() => _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget> {
  late final ConnectivityService _connectivityService;
  late final OfflineModeService _offlineModeService;
  bool _isOnline = true;
  
  @override
  void initState() {
    super.initState();
    _connectivityService = getIt<ConnectivityService>();
    _offlineModeService = getIt<OfflineModeService>();
    
    _initializeConnectivityStatus();
    _listenToConnectivityChanges();
  }
  
  void _initializeConnectivityStatus() {
    _isOnline = _connectivityService.isOnline;
    _checkOfflineWarning();
  }
  
  void _listenToConnectivityChanges() {
    _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
        _checkOfflineWarning();
      }
    });
  }
  
  void _checkOfflineWarning() async {
    if (!_isOnline) {
      final shouldShow = await _offlineModeService.shouldShowOfflineWarning();
      if (mounted && shouldShow) {
        _showOfflineDialog();
      }
    }
  }
  
  void _showOfflineDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.wifi_off, color: Colors.orange, size: 48),
        title: const Text('Mode Offline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aplikasi berjalan dalam mode offline. Beberapa fitur mungkin tidak tersedia:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.close, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Chat AI')),
              ],
            ),
            const Row(
              children: [
                Icon(Icons.close, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Konten AI (musik, artikel)')),
              ],
            ),
            const Row(
              children: [
                Icon(Icons.close, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Sinkronisasi cloud')),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Fitur yang tetap tersedia:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Row(
              children: [
                Icon(Icons.check, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Pelacakan mood')),
              ],
            ),
            const Row(
              children: [
                Icon(Icons.check, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Tes psikologi')),
              ],
            ),
            const Row(
              children: [
                Icon(Icons.check, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Riwayat lokal')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _offlineModeService.markOfflineWarningShown();
              Navigator.of(context).pop();
            },
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showStatusBar && !_isOnline)
          _buildOfflineStatusBar(),
        Expanded(child: widget.child),
      ],
    );
  }
  
  Widget _buildOfflineStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode offline - Fitur terbatas tersedia',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await _connectivityService.checkConnectivity();
            },
            icon: Icon(
              Icons.refresh,
              color: Colors.orange.shade700,
              size: 16,
            ),
            label: Text(
              'Coba lagi',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget untuk menampilkan fallback content saat offline
class OfflineFallbackWidget extends StatelessWidget {
  final String message;
  final List<String>? availableFeatures;
  final VoidCallback? onRetry;
  
  const OfflineFallbackWidget({
    super.key,
    required this.message,
    this.availableFeatures,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (availableFeatures != null && availableFeatures!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Fitur yang tersedia:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...availableFeatures!.map(
                (feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(feature),
                    ],
                  ),
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan status fitur (tersedia/tidak tersedia)
class FeatureStatusIndicator extends StatelessWidget {
  final String featureName;
  final bool isAvailable;
  final String? disabledReason;
  
  const FeatureStatusIndicator({
    super.key,
    required this.featureName,
    required this.isAvailable,
    this.disabledReason,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            featureName,
            style: TextStyle(
              color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isAvailable && disabledReason != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: disabledReason!,
              child: Icon(
                Icons.info_outline,
                color: Colors.red.shade700,
                size: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
