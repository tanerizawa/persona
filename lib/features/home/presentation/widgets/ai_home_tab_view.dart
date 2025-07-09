import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/home_content_entities.dart';
import '../../domain/usecases/smart_content_manager.dart';

class AIHomeTabView extends StatefulWidget {
  const AIHomeTabView({super.key});

  @override
  State<AIHomeTabView> createState() => _AIHomeTabViewState();
}

class _AIHomeTabViewState extends State<AIHomeTabView> {
  late SmartContentManager _smartContentManager;
  late ConnectivityService _connectivityService;
  List<AIContent> _aiContent = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _smartContentManager = getIt<SmartContentManager>();
    _connectivityService = getIt<ConnectivityService>();
    _checkConnectivityAndLoadContent();
  }

  Future<void> _checkConnectivityAndLoadContent() async {
    final isOnline = _connectivityService.hasInternet;
    setState(() {
      _isOffline = !isOnline;
    });
    
    if (isOnline) {
      _loadAIContent();
    } else {
      _loadOfflineContent();
    }
  }

  Future<void> _loadAIContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = await _smartContentManager.getSmartContent();
      if (mounted) {
        setState(() {
          _aiContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat konten. Menggunakan konten default.';
          _isLoading = false;
        });
      }
      // Load fallback content
      _loadFallbackContent();
    }
  }

  void _loadFallbackContent() {
    // Load offline content when online content fails
    _loadOfflineContent();
  }

  void _loadOfflineContent() {
    // Provide comprehensive offline content with local suggestions
    final now = DateTime.now();
    
    if (mounted) {
      setState(() {
        _aiContent = [
          // Offline self-reflection content
          AIContent(
            id: 'offline_reflection_1',
            type: 'journal_prompt',
            title: '🌱 Refleksi Diri Hari Ini',
            subtitle: 'Pengembangan Diri',
            description: 'Luangkan waktu untuk merefleksikan pencapaian dan pembelajaran hari ini.',
            metadata: {
              'content': 'Apa yang telah saya pelajari hari ini? Bagaimana saya bisa berkembang lebih baik besok?',
              'category': 'refleksi',
              'offline': true,
            },
            generatedAt: now,
            relevanceScore: 0.9,
          ),
          
          // Offline mindfulness content
          AIContent(
            id: 'offline_mindfulness_1',
            type: 'article',
            title: '🧘‍♀️ Latihan Mindfulness 5 Menit',
            subtitle: 'Kesehatan Mental',
            description: 'Teknik pernapasan sederhana untuk mengurangi stres dan meningkatkan fokus.',
            metadata: {
              'content': '1. Duduk dengan nyaman\n2. Tutup mata dan fokus pada napas\n3. Hitung napas dari 1-10\n4. Ulangi 3 kali',
              'category': 'mindfulness',
              'offline': true,
            },
            generatedAt: now,
            relevanceScore: 0.85,
          ),
          
          // Offline productivity tip
          AIContent(
            id: 'offline_productivity_1',
            type: 'article',
            title: '⚡ Tips Produktivitas: Teknik Pomodoro',
            subtitle: 'Manajemen Waktu',
            description: 'Manajemen waktu efektif dengan sesi fokus 25 menit.',
            metadata: {
              'content': 'Bekerja selama 25 menit dengan fokus penuh, lalu istirahat 5 menit. Ulangi 4 kali, lalu istirahat panjang 15-30 menit.',
              'category': 'produktivitas',
              'offline': true,
            },
            generatedAt: now,
            relevanceScore: 0.8,
          ),
          
          // Offline inspiration
          AIContent(
            id: 'offline_inspiration_1',
            type: 'quote',
            title: '✨ Kutipan Inspiratif',
            subtitle: 'Motivasi Harian',
            description: 'Kata-kata motivasi untuk menghadapi tantangan hari ini.',
            metadata: {
              'content': '"Kesuksesan bukanlah kunci kebahagiaan. Kebahagiaan adalah kunci kesuksesan. Jika Anda mencintai apa yang Anda lakukan, Anda akan sukses." - Albert Schweitzer',
              'category': 'inspirasi',
              'offline': true,
            },
            generatedAt: now,
            relevanceScore: 0.9,
          ),
          
          // Offline health tip
          AIContent(
            id: 'offline_health_1',
            type: 'article',
            title: '💧 Tips Kesehatan: Hidrasi yang Cukup',
            subtitle: 'Kesehatan Fisik',
            description: 'Pentingnya menjaga asupan air untuk kesehatan optimal.',
            metadata: {
              'content': 'Minum air 8 gelas per hari (2 liter). Tanda tubuh terhidrasi: urin berwarna kuning muda, tidak merasa haus berlebihan, kulit elastis.',
              'category': 'kesehatan',
              'offline': true,
            },
            generatedAt: now,
            relevanceScore: 0.75,
          ),
        ];
        _isLoading = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _refreshContent() async {
    // Check connectivity first
    await _checkConnectivityAndLoadContent();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshContent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header with personalized greeting
            _buildPersonalizedWelcomeHeader(context),
            const SizedBox(height: AppConstants.largePadding),
            
            // Offline mode indicator
            if (_isOffline)
              _buildOfflineIndicator(context),
            
            // Error message if any
            if (_errorMessage != null)
              _buildErrorMessage(context),
            
            // Loading indicator
            if (_isLoading)
              _buildLoadingIndicator(context)
            else ...[
              // AI Curated Content Sections
              _buildMusicRecommendations(context),
              const SizedBox(height: AppConstants.largePadding),
              
              _buildArticlesSection(context),
              const SizedBox(height: AppConstants.largePadding),
              
              _buildDailyQuote(context),
              const SizedBox(height: AppConstants.largePadding),
              
              _buildJournalSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedWelcomeHeader(BuildContext context) {
    final currentHour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (currentHour < 12) {
      greeting = 'Selamat Pagi';
      greetingIcon = Symbols.wb_sunny;
    } else if (currentHour < 17) {
      greeting = 'Selamat Siang';
      greetingIcon = Symbols.light_mode;
    } else {
      greeting = 'Selamat Malam';
      greetingIcon = Symbols.nights_stay;
    }

    // Get personalized message based on recent activity
    String personalizedMessage = 'Bagaimana perasaan Anda hari ini?';
    
    // TODO: Customize based on mood trend and recent activities
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      greetingIcon,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  personalizedMessage,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Row(
                  children: [
                    Icon(
                      Symbols.auto_awesome,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Konten dipersonalisasi untuk Anda',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Symbols.psychology,
            size: 48,
            color: Colors.white,
            fill: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.largePadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Symbols.warning,
            color: Colors.orange,
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: _refreshContent,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppConstants.defaultPadding),
            Text('Memuat konten yang dipersonalisasi untuk Anda...'),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicRecommendations(BuildContext context) {
    final musicContent = _aiContent.where((content) => content.type == 'music').toList();
    
    return _buildContentSection(
      context,
      title: AppStrings.musicRecommendations,
      icon: Symbols.music_note,
      children: musicContent.isNotEmpty
          ? musicContent.map((content) {
              final music = content as MusicRecommendation;
              return _buildMusicCard(
                context,
                music.title,
                '${music.artist} • ${music.genre}',
                Symbols.headphones,
                music.description,
                onPlay: () {
                  // TODO: Implement music playback
                },
              );
            }).toList()
          : [
              _buildMusicCard(
                context,
                'Lo-fi Hip Hop untuk Fokus',
                'Study Playlist',
                Symbols.headphones,
                'Musik untuk meningkatkan konsentrasi',
                onPlay: () {},
              ),
            ],
    );
  }

  Widget _buildArticlesSection(BuildContext context) {
    final articleContent = _aiContent.where((content) => content.type == 'article').toList();
    
    return _buildContentSection(
      context,
      title: AppStrings.articlesForYou,
      icon: Symbols.article,
      children: articleContent.isNotEmpty
          ? articleContent.map((content) {
              final article = content as ArticleRecommendation;
              return _buildArticleCard(
                context,
                article.title,
                article.source,
                '${article.readingTimeMinutes} min read',
                article.description,
                onRead: () {
                  // TODO: Implement article reading
                },
              );
            }).toList()
          : [
              _buildArticleCard(
                context,
                'Mindfulness dalam Kehidupan Sehari-hari',
                'Psychology Today',
                '5 min read',
                'Praktik sederhana untuk kesehatan mental yang lebih baik',
                onRead: () {},
              ),
            ],
    );
  }

  Widget _buildDailyQuote(BuildContext context) {
    final quoteContent = _aiContent.where((content) => content.type == 'quote').toList();
    DailyQuote? quote;
    
    if (quoteContent.isNotEmpty) {
      quote = quoteContent.first as DailyQuote;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.format_quote,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  AppStrings.dailyQuote,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (quote != null)
                  Chip(
                    label: Text(
                      quote.category,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote?.quote ?? '"Masa depan milik mereka yang percaya pada keindahan impian mereka."',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    '— ${quote?.author ?? 'Eleanor Roosevelt'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (quote?.explanation != null) ...[
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      quote!.explanation!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalSection(BuildContext context) {
    final journalContent = _aiContent.where((content) => content.type == 'journal_prompt').toList();
    JournalPrompt? prompt;
    
    if (journalContent.isNotEmpty) {
      prompt = journalContent.first as JournalPrompt;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.edit_note,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  AppStrings.journalEntry,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Open journal writing interface
                  },
                  icon: const Icon(Symbols.add),
                  label: const Text('Tulis'),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prompt Hari Ini:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    prompt?.prompt ?? 'Tuliskan pikiran dan perasaan Anda hari ini. Jurnal membantu merefleksikan pengalaman dan meningkatkan kesehatan mental.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (prompt?.followUpQuestions.isNotEmpty ?? false) ...[
                    const SizedBox(height: AppConstants.defaultPadding),
                    Text(
                      'Pertanyaan lanjutan:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    ...prompt!.followUpQuestions.map((question) => Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Text(
                        '• $question',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Icon(
                  Symbols.auto_awesome,
                  size: 16,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildMusicCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String? description, {
    required VoidCallback onPlay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (description != null)
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          onPressed: onPlay,
          icon: const Icon(Symbols.play_arrow),
        ),
        onTap: onPlay,
      ),
    );
  }

  Widget _buildArticleCard(
    BuildContext context,
    String title,
    String source,
    String readTime,
    String? description, {
    required VoidCallback onRead,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            Symbols.article,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    source,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(' • $readTime'),
              ],
            ),
            if (description != null)
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          onPressed: onRead,
          icon: const Icon(Symbols.arrow_forward),
        ),
        onTap: onRead,
      ),
    );
  }

  Widget _buildOfflineIndicator(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppConstants.largePadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.wifi_off,
            color: Colors.blue.shade600,
            size: 24,
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Offline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Menampilkan konten lokal yang tersimpan. Konten akan diperbarui saat terhubung ke internet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
