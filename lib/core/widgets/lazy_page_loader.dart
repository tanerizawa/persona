import 'package:flutter/material.dart';
import '../services/lazy_page_service.dart';

/// Widget untuk lazy loading halaman dengan loading indicator
class LazyPageLoader extends StatefulWidget {
  final int pageIndex;
  final Widget Function() pageBuilder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final bool isHeavyPage;

  const LazyPageLoader({
    super.key,
    required this.pageIndex,
    required this.pageBuilder,
    this.loadingWidget,
    this.errorWidget,
    this.isHeavyPage = false,
  });

  @override
  State<LazyPageLoader> createState() => _LazyPageLoaderState();
}

class _LazyPageLoaderState extends State<LazyPageLoader> {
  final LazyPageService _lazyPageService = LazyPageService();
  Widget? _loadedPage;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Mark sebagai heavy page jika diperlukan
    if (widget.isHeavyPage) {
      _lazyPageService.markAsHeavyPage(widget.pageIndex);
    }
    
    _loadPage();
  }

  Future<void> _loadPage() async {
    // Cek cache dulu
    final cachedPage = _lazyPageService.getCachedPage(widget.pageIndex);
    if (cachedPage != null) {
      if (mounted) {
        setState(() {
          _loadedPage = cachedPage;
          _hasError = false;
        });
      }
      return;
    }

    // Jika sedang loading, tunggu
    if (_lazyPageService.isLoading(widget.pageIndex)) {
      return;
    }

    try {
      _lazyPageService.setLoading(widget.pageIndex, true);
      
      // Simulate loading delay untuk heavy pages
      if (widget.isHeavyPage) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Build page
      final page = widget.pageBuilder();
      
      // Cache page
      _lazyPageService.cachePage(widget.pageIndex, page);
      
      if (mounted) {
        setState(() {
          _loadedPage = page;
          _hasError = false;
        });
      }
    } catch (e) {
      _lazyPageService.setLoading(widget.pageIndex, false);
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }

    if (_loadedPage != null) {
      return _loadedPage!;
    }

    return widget.loadingWidget ?? _buildDefaultLoadingWidget();
  }

  Widget _buildDefaultLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat halaman...'),
        ],
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat halaman',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _lazyPageService.refreshPage(widget.pageIndex);
              _loadPage();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
