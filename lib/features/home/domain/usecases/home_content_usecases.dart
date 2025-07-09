import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

import '../entities/home_content_entities.dart';
import '../../../little_brain/domain/repositories/little_brain_repository.dart';
import '../../../growth/domain/usecases/mood_tracking_usecases.dart';
import '../../../psychology/domain/usecases/psychology_testing_usecases.dart';
import '../../../../core/api/openrouter_api_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/performance_service.dart';
import '../../../../core/services/performance_monitor.dart';

@injectable
class HomeContentUseCases {
  final LittleBrainRepository _littleBrainRepository;
  final MoodTrackingUseCases _moodTracking;
  final PsychologyTestingUseCases _psychologyTesting;
  final OpenRouterApiService _openRouterService;
  final Uuid _uuid = const Uuid();
  final LoggingService _logger = LoggingService();
  final PerformanceService _performanceService = PerformanceService();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  // Prevent multiple concurrent content generation attempts
  bool _isGenerating = false;
  Completer<List<AIContent>>? _generationCompleter;

  HomeContentUseCases(
    this._littleBrainRepository,
    this._moodTracking,
    this._psychologyTesting,
    this._openRouterService,
  );

  /// Generate personalized content for home dashboard
  Future<List<AIContent>> generatePersonalizedContent() async {
    // If already generating, wait for the current generation to complete
    if (_isGenerating) {
      if (_generationCompleter != null) {
        return await _generationCompleter!.future;
      }
      return _getFallbackContent();
    }

    // Start generating
    _isGenerating = true;
    _generationCompleter = Completer<List<AIContent>>();

    try {
      final result = await _generateContentInternal();
      _generationCompleter!.complete(result);
      return result;
    } catch (e) {
      final fallback = _getFallbackContent();
      _generationCompleter!.complete(fallback);
      return fallback;
    } finally {
      _isGenerating = false;
      _generationCompleter = null;
    }
  }

  /// Internal method to generate content
  Future<List<AIContent>> _generateContentInternal() async {
    return await _performanceService.executeWithTracking(
      'generate_personalized_content',
      () async {
        final stopwatch = Stopwatch()..start();
        
        try {
          // 1. Build personalization context from Little Brain data
          final context = await _buildPersonalizationContext();
          
          // 2. Generate different types of content using batch operations
          final allContent = <AIContent>[];
          
          // Generate content with performance tracking
          try {
            final musicRecommendations = await _generateMusicRecommendations(context);
            allContent.addAll(musicRecommendations);
          } catch (e) {
            _logger.error('Failed to generate music recommendations: $e');
          }
          
          try {
            final articleRecommendations = await _generateArticleRecommendations(context);
            allContent.addAll(articleRecommendations);
          } catch (e) {
            _logger.error('Failed to generate article recommendations: $e');
          }
          
          try {
            final dailyQuote = await _generateDailyQuote(context);
            allContent.addAll(dailyQuote);
          } catch (e) {
            _logger.error('Failed to generate daily quote: $e');
          }
          
          try {
            final journalPrompt = await _generateJournalPrompt(context);
            allContent.addAll(journalPrompt);
          } catch (e) {
            _logger.error('Failed to generate journal prompt: $e');
          }

          // 3. Sort by relevance score (highest first)
          allContent.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
          
          stopwatch.stop();
          _performanceMonitor.trackOperation('content_generation_total', stopwatch.elapsedMilliseconds);
          
          return allContent;
        } catch (e) {
          stopwatch.stop();
          _logger.error('Content generation failed after ${stopwatch.elapsedMilliseconds}ms: $e');
          // Return fallback content on error
          return _getFallbackContent();
        }
      },
    );
  }

  /// Build personalization context from user data
  Future<PersonalizationContext> _buildPersonalizationContext() async {
    try {
      // Get recent mood data
      final recentMoods = await _moodTracking.getRecentMoodEntries(limit: 7);
      final moodAnalytics = await _moodTracking.getMoodAnalytics();
      
      // Get psychology data
      final psychologyAnalytics = await _psychologyTesting.getPsychologyAnalytics();
      
      // Get conversation topics from Little Brain
      final recentMemories = await _littleBrainRepository.getAllMemories();
      final conversationMemories = recentMemories
          .where((m) => m.source == 'chat' && m.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7))))
          .take(20)
          .toList();

      // Extract interests from conversation topics
      final interests = <String>{};
      for (final memory in conversationMemories) {
        interests.addAll(memory.tags.where((tag) => !['chat', 'conversation'].contains(tag)));
      }

      // Calculate current mood level
      double? currentMoodLevel;
      if (recentMoods.isNotEmpty) {
        currentMoodLevel = recentMoods.first.moodLevel.toDouble();
      }

      // Determine mood trend
      String? moodTrend;
      if (moodAnalytics.trends.isNotEmpty) {
        final weeklyTrend = moodAnalytics.trends.firstWhere(
          (t) => t.period == 'week',
          orElse: () => moodAnalytics.trends.first,
        );
        if (weeklyTrend.trendDirection > 0.1) {
          moodTrend = 'improving';
        } else if (weeklyTrend.trendDirection < -0.1) {
          moodTrend = 'declining';
        } else {
          moodTrend = 'stable';
        }
      }

      return PersonalizationContext(
        currentMoodLevel: currentMoodLevel,
        dominantMoodTrend: moodTrend,
        mbtiType: psychologyAnalytics.latestMBTI?.personalityType,
        currentMentalHealthLevel: psychologyAnalytics.latestBDI?.level.name,
        recentInterests: interests.take(5).toList(),
        lifeAreaFocus: [], // TODO: Extract from life tree data
      );
    } catch (e) {
      return const PersonalizationContext();
    }
  }

  /// Generate music recommendations based on context
  Future<List<MusicRecommendation>> _generateMusicRecommendations(PersonalizationContext context) async {
    try {
      final prompt = _buildMusicPrompt(context);
      final request = ChatCompletionRequest(
        model: AppConstants.defaultAiModel,
        messages: [
          ChatMessage(role: 'system', content: 'You are a helpful music recommendation assistant.'),
          ChatMessage(role: 'user', content: prompt),
        ],
        maxTokens: 500,
        temperature: 0.7,
      );
      
      final response = await _openRouterService.createChatCompletion(request);
      final content = response.choices.first.message.content;
      
      // Parse AI response and create music recommendations
      return _parseMusicRecommendations(content);
    } catch (e) {
      return _getFallbackMusicRecommendations();
    }
  }

  /// Generate article recommendations based on context
  Future<List<ArticleRecommendation>> _generateArticleRecommendations(PersonalizationContext context) async {
    try {
      final prompt = _buildArticlePrompt(context);
      final request = ChatCompletionRequest(
        model: AppConstants.defaultAiModel,
        messages: [
          ChatMessage(role: 'system', content: 'You are a helpful article recommendation assistant for personal development.'),
          ChatMessage(role: 'user', content: prompt),
        ],
        maxTokens: 500,
        temperature: 0.7,
      );
      
      final response = await _openRouterService.createChatCompletion(request);
      final content = response.choices.first.message.content;
      
      return _parseArticleRecommendations(content);
    } catch (e) {
      return _getFallbackArticleRecommendations();
    }
  }

  /// Generate daily quote based on context
  Future<List<DailyQuote>> _generateDailyQuote(PersonalizationContext context) async {
    try {
      final prompt = _buildQuotePrompt(context);
      final request = ChatCompletionRequest(
        model: AppConstants.defaultAiModel,
        messages: [
          ChatMessage(role: 'system', content: 'You are a wise quote curator who provides inspirational quotes.'),
          ChatMessage(role: 'user', content: prompt),
        ],
        maxTokens: 200,
        temperature: 0.7,
      );
      
      final response = await _openRouterService.createChatCompletion(request);
      final content = response.choices.first.message.content;
      
      return _parseQuoteRecommendation(content);
    } catch (e) {
      return _getFallbackQuote();
    }
  }

  /// Generate journal prompt based on context
  Future<List<JournalPrompt>> _generateJournalPrompt(PersonalizationContext context) async {
    try {
      final prompt = _buildJournalPrompt(context);
      final request = ChatCompletionRequest(
        model: AppConstants.defaultAiModel,
        messages: [
          ChatMessage(role: 'system', content: 'You are a thoughtful journaling guide who creates meaningful prompts.'),
          ChatMessage(role: 'user', content: prompt),
        ],
        maxTokens: 300,
        temperature: 0.8,
      );
      
      final response = await _openRouterService.createChatCompletion(request);
      final content = response.choices.first.message.content;
      
      return _parseJournalPrompt(content);
    } catch (e) {
      return _getFallbackJournalPrompt();
    }
  }

  String _buildMusicPrompt(PersonalizationContext context) {
    final buffer = StringBuffer();
    buffer.writeln('Generate 3 music recommendations based on the following user context:');
    
    if (context.currentMoodLevel != null) {
      buffer.writeln('Current mood: ${context.currentMoodLevel}/10');
    }
    if (context.dominantMoodTrend != null) {
      buffer.writeln('Mood trend: ${context.dominantMoodTrend}');
    }
    if (context.mbtiType != null) {
      buffer.writeln('Personality type: ${context.mbtiType}');
    }
    if (context.recentInterests.isNotEmpty) {
      buffer.writeln('Recent interests: ${context.recentInterests.join(', ')}');
    }

    buffer.writeln('\nPlease provide recommendations in this JSON format:');
    buffer.writeln('[{"title": "Song/Playlist Title", "artist": "Artist Name", "genre": "Genre", "mood": "Target Mood", "duration": 180, "description": "Why this fits the user"}]');
    
    return buffer.toString();
  }

  String _buildArticlePrompt(PersonalizationContext context) {
    final buffer = StringBuffer();
    buffer.writeln('Generate 3 article recommendations for personal development based on:');
    
    if (context.currentMoodLevel != null) {
      buffer.writeln('Current mood: ${context.currentMoodLevel}/10');
    }
    if (context.mbtiType != null) {
      buffer.writeln('Personality type: ${context.mbtiType}');
    }
    if (context.currentMentalHealthLevel != null) {
      buffer.writeln('Mental health level: ${context.currentMentalHealthLevel}');
    }
    if (context.recentInterests.isNotEmpty) {
      buffer.writeln('Interests: ${context.recentInterests.join(', ')}');
    }

    buffer.writeln('\nProvide in JSON format:');
    buffer.writeln('[{"title": "Article Title", "author": "Author Name", "source": "Source", "readingTime": 5, "tags": ["tag1", "tag2"], "description": "Summary"}]');
    
    return buffer.toString();
  }

  String _buildQuotePrompt(PersonalizationContext context) {
    final buffer = StringBuffer();
    buffer.writeln('Generate 1 inspirational quote that matches the user\'s current situation:');
    
    if (context.currentMoodLevel != null) {
      final moodDesc = context.currentMoodLevel! > 7 ? 'positive' : 
                      context.currentMoodLevel! < 4 ? 'challenging' : 'neutral';
      buffer.writeln('Current mood: $moodDesc');
    }
    if (context.dominantMoodTrend != null) {
      buffer.writeln('Mood trend: ${context.dominantMoodTrend}');
    }
    if (context.mbtiType != null) {
      buffer.writeln('Personality: ${context.mbtiType}');
    }

    buffer.writeln('\nProvide in JSON format:');
    buffer.writeln('{"quote": "Quote text", "author": "Author Name", "category": "Category", "explanation": "Why this quote fits"}');
    
    return buffer.toString();
  }

  String _buildJournalPrompt(PersonalizationContext context) {
    final buffer = StringBuffer();
    buffer.writeln('Generate 1 thoughtful journal prompt based on:');
    
    if (context.currentMoodLevel != null) {
      buffer.writeln('Current mood: ${context.currentMoodLevel}/10');
    }
    if (context.dominantMoodTrend != null) {
      buffer.writeln('Recent trend: ${context.dominantMoodTrend}');
    }
    if (context.recentInterests.isNotEmpty) {
      buffer.writeln('Recent topics: ${context.recentInterests.join(', ')}');
    }

    buffer.writeln('\nProvide in JSON format:');
    buffer.writeln('{"prompt": "Journal prompt", "category": "Category", "followUpQuestions": ["Question 1", "Question 2"]}');
    
    return buffer.toString();
  }

  // Parser methods for AI responses
  List<MusicRecommendation> _parseMusicRecommendations(String response) {
    // TODO: Implement JSON parsing for music recommendations
    return _getFallbackMusicRecommendations();
  }

  List<ArticleRecommendation> _parseArticleRecommendations(String response) {
    // TODO: Implement JSON parsing for article recommendations
    return _getFallbackArticleRecommendations();
  }

  List<DailyQuote> _parseQuoteRecommendation(String response) {
    // TODO: Implement JSON parsing for quote
    return _getFallbackQuote();
  }

  List<JournalPrompt> _parseJournalPrompt(String response) {
    // TODO: Implement JSON parsing for journal prompt
    return _getFallbackJournalPrompt();
  }

  // Fallback content methods
  List<MusicRecommendation> _getFallbackMusicRecommendations() {
    return [
      MusicRecommendation(
        id: _uuid.v4(),
        title: 'Lo-fi Hip Hop untuk Fokus',
        subtitle: 'Study Playlist',
        artist: 'ChillHop Music',
        genre: 'Lo-fi',
        mood: 'Fokus',
        duration: 3600,
        generatedAt: DateTime.now(),
        relevanceScore: 0.8,
      ),
      MusicRecommendation(
        id: _uuid.v4(),
        title: 'Musik Relaksasi',
        subtitle: 'Meditation Mix',
        artist: 'Calm Music',
        genre: 'Ambient',
        mood: 'Relaksasi',
        duration: 2400,
        generatedAt: DateTime.now(),
        relevanceScore: 0.7,
      ),
    ];
  }

  List<ArticleRecommendation> _getFallbackArticleRecommendations() {
    return [
      ArticleRecommendation(
        id: _uuid.v4(),
        title: 'Mindfulness dalam Kehidupan Sehari-hari',
        subtitle: 'Praktik sederhana untuk kesehatan mental',
        author: 'Dr. Sarah Wilson',
        source: 'Psychology Today',
        readingTimeMinutes: 5,
        tags: ['mindfulness', 'mental-health'],
        generatedAt: DateTime.now(),
        relevanceScore: 0.9,
      ),
    ];
  }

  List<DailyQuote> _getFallbackQuote() {
    return [
      DailyQuote(
        id: _uuid.v4(),
        quote: 'Masa depan milik mereka yang percaya pada keindahan impian mereka.',
        author: 'Eleanor Roosevelt',
        category: 'Inspirasi',
        generatedAt: DateTime.now(),
        relevanceScore: 0.8,
      ),
    ];
  }

  List<JournalPrompt> _getFallbackJournalPrompt() {
    return [
      JournalPrompt(
        id: _uuid.v4(),
        prompt: 'Apa tiga hal yang Anda syukuri hari ini dan mengapa?',
        category: 'Gratitude',
        followUpQuestions: [
          'Bagaimana hal-hal ini mempengaruhi mood Anda?',
          'Apa yang bisa Anda lakukan untuk mengalami lebih banyak momen seperti ini?',
        ],
        generatedAt: DateTime.now(),
        relevanceScore: 0.8,
      ),
    ];
  }

  List<AIContent> _getFallbackContent() {
    final content = <AIContent>[];
    content.addAll(_getFallbackMusicRecommendations());
    content.addAll(_getFallbackArticleRecommendations());
    content.addAll(_getFallbackQuote());
    content.addAll(_getFallbackJournalPrompt());
    return content;
  }
}
