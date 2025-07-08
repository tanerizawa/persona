import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../domain/entities/home_content_entities.dart';
import '../../domain/usecases/home_content_usecases.dart';

class AIHomeTabView extends StatefulWidget {
  const AIHomeTabView({super.key});

  @override
  State<AIHomeTabView> createState() => _AIHomeTabViewState();
}

class _AIHomeTabViewState extends State<AIHomeTabView> {
  late HomeContentUseCases _homeContentUseCases;
  List<AIContent> _aiContent = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _homeContentUseCases = getIt<HomeContentUseCases>();
    _loadAIContent();
  }

  Future<void> _loadAIContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = await _homeContentUseCases.generatePersonalizedContent();
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
    // This will be populated with fallback content from usecases
    if (mounted) {
      setState(() {
        _aiContent = [];
      });
    }
  }

  Future<void> _refreshContent() async {
    await _loadAIContent();
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
}
