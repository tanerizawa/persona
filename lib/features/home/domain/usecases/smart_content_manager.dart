import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entities/home_content_entities.dart';
import '../../../little_brain/domain/repositories/little_brain_repository.dart';
import '../../../growth/domain/usecases/mood_tracking_usecases.dart';
import '../../../psychology/domain/usecases/psychology_testing_usecases.dart';
import '../../../../core/api/openrouter_api_service.dart';

/// Smart Content Manager - Mengoptimalkan Little Brain dan meminimalkan API usage
@singleton
class SmartContentManager {
  final LittleBrainRepository _littleBrainRepository;
  final MoodTrackingUseCases _moodTracking;
  final PsychologyTestingUseCases _psychologyTesting;
  final OpenRouterApiService _openRouterService; // Used for minimal API calls when needed
  final SharedPreferences _prefs;

  // Cache management
  static const String _cacheKeyContent = 'smart_content_cache';
  static const String _cacheKeyTimestamp = 'smart_content_timestamp';
  static const String _cacheKeyUserPattern = 'user_pattern_cache';
  
  // Content refresh intervals
  static const Duration _contentValidDuration = Duration(hours: 6); // Content valid for 6 hours
  static const Duration _patternValidDuration = Duration(days: 1);   // User pattern valid for 1 day
  
  // API usage tracking
  static const String _apiUsageToday = 'api_usage_today';
  static const String _lastApiDate = 'last_api_date';
  static const int _maxApiCallsPerDay = 12; // Limit API calls to 12 per day

  SmartContentManager(
    this._littleBrainRepository,
    this._moodTracking,
    this._psychologyTesting,
    this._openRouterService,
    this._prefs,
  );

  /// Main method: Get content with smart caching and Little Brain optimization
  Future<List<AIContent>> getSmartContent() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Update metrics
      await _updateMetrics('total_requests', 1);
      
      // 1. Check if we have valid cached content
      final cachedContent = await _getValidCachedContent();
      if (cachedContent.isNotEmpty) {
        stopwatch.stop();
        await _updateMetrics('cache_hits', 1);
        await _updateMetrics('total_generation_time', stopwatch.elapsedMilliseconds);
        debugPrint('📦 [SmartContent] Using cached content (${stopwatch.elapsedMilliseconds}ms)');
        await _logPerformanceMetrics('cache', stopwatch.elapsedMilliseconds, cachedContent.length);
        return cachedContent;
      }

      // 2. Generate content using Little Brain intelligence
      final localContent = await _generateContentFromLittleBrain();
      if (localContent.isNotEmpty) {
        await _cacheContent(localContent);
        stopwatch.stop();
        await _updateMetrics('little_brain_generated', 1);
        await _updateMetrics('total_generation_time', stopwatch.elapsedMilliseconds);
        debugPrint('🧠 [SmartContent] Generated from Little Brain (${stopwatch.elapsedMilliseconds}ms) - ${localContent.length} items');
        await _logPerformanceMetrics('little_brain', stopwatch.elapsedMilliseconds, localContent.length);
        return localContent;
      }

      // 3. Only use API if necessary and within daily limits
      if (await _canUseAPI()) {
        final apiContent = await _generateContentFromAPI();
        await _cacheContent(apiContent);
        await _incrementApiUsage();
        stopwatch.stop();
        await _updateMetrics('api_calls', 1);
        await _updateMetrics('total_generation_time', stopwatch.elapsedMilliseconds);
        debugPrint('🌐 [SmartContent] Generated from API (${await _getTodayApiUsage()}/12) in ${stopwatch.elapsedMilliseconds}ms');
        await _logPerformanceMetrics('api', stopwatch.elapsedMilliseconds, apiContent.length);
        return apiContent;
      }

      // 4. Fallback to default content
      stopwatch.stop();
      await _updateMetrics('fallback_used', 1);
      await _updateMetrics('total_generation_time', stopwatch.elapsedMilliseconds);
      debugPrint('💡 [SmartContent] Using fallback content (${stopwatch.elapsedMilliseconds}ms)');
      await _logPerformanceMetrics('fallback', stopwatch.elapsedMilliseconds, 4);
      return _getFallbackContent();

    } catch (e) {
      stopwatch.stop();
      await _updateMetrics('errors', 1);
      await _logError('getSmartContent', e.toString(), stopwatch.elapsedMilliseconds);
      debugPrint('❌ [SmartContent] Error in ${stopwatch.elapsedMilliseconds}ms: $e');
      return _getFallbackContent();
    }
  }

  /// Generate content using Little Brain data and local intelligence
  Future<List<AIContent>> _generateContentFromLittleBrain() async {
    try {
      // Get user patterns from Little Brain
      final userPattern = await _buildUserPatternFromLittleBrain();
      
      // Generate content based on patterns without API
      final content = <AIContent>[];
      
      // 1. Music based on mood patterns
      content.addAll(await _generateMusicFromPattern(userPattern));
      
      // 2. Articles based on interests and MBTI
      content.addAll(await _generateArticlesFromPattern(userPattern));
      
      // 3. Quote based on current mood and challenges
      content.addAll(await _generateQuoteFromPattern(userPattern));
      
      // 4. Journal prompt based on recent patterns
      content.addAll(await _generateJournalFromPattern(userPattern));

      // Sort by relevance
      content.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      
      // Background: Schedule next content preload
      _scheduleContentPreload();
      
      return content;
    } catch (e) {
      debugPrint('🚨 [SmartContent] Little Brain generation failed: $e');
      return [];
    }
  }

  /// Schedule background content preload for better performance
  void _scheduleContentPreload() {
    // Schedule content generation for next expected usage
    Timer(const Duration(hours: 3), () async {
      try {
        debugPrint('🔄 [SmartContent] Background preload started');
        final preloadedContent = await _generateContentFromLittleBrain();
        if (preloadedContent.isNotEmpty) {
          await _cacheContent(preloadedContent);
          debugPrint('✅ [SmartContent] Background preload completed - ${preloadedContent.length} items');
        }
      } catch (e) {
        debugPrint('❌ [SmartContent] Background preload failed: $e');
      }
    });
  }

  /// Build comprehensive user pattern from Little Brain data
  Future<UserPattern> _buildUserPatternFromLittleBrain() async {
    // Check if we have cached pattern
    final cachedPattern = await _getCachedUserPattern();
    if (cachedPattern != null) {
      return cachedPattern;
    }

    // Build new pattern from Little Brain
    final memories = await _littleBrainRepository.getAllMemories();
    final recentMoods = await _moodTracking.getRecentMoodEntries(limit: 14);
    final psychoAnalytics = await _psychologyTesting.getPsychologyAnalytics();

    // Analyze patterns
    final pattern = UserPattern(
      // Mood patterns
      averageMood: recentMoods.isNotEmpty 
          ? recentMoods.map((m) => m.moodLevel).reduce((a, b) => a + b) / recentMoods.length 
          : 7.0,
      moodTrend: _calculateMoodTrend(recentMoods),
      commonMoodTriggers: _extractMoodTriggers(memories),
      
      // Interest patterns
      topInterests: _extractTopInterests(memories),
      conversationThemes: _extractConversationThemes(memories),
      learningAreas: _extractLearningAreas(memories),
      
      // Personality insights
      mbtiType: psychoAnalytics.latestMBTI?.personalityType,
      mentalHealthLevel: psychoAnalytics.latestBDI?.level.name,
      personalityTraits: _extractPersonalityTraits(memories),
      
      // Behavioral patterns
      activeHours: _extractActiveHours(memories),
      preferredContentTypes: _extractContentPreferences(memories),
      responsePatterns: _extractResponsePatterns(memories),
      
      // Context
      lastUpdated: DateTime.now(),
    );

    // Cache the pattern
    await _cacheUserPattern(pattern);
    return pattern;
  }

  /// Generate music recommendations from user patterns
  Future<List<MusicRecommendation>> _generateMusicFromPattern(UserPattern pattern) async {
    final recommendations = <MusicRecommendation>[];
    
    // Based on mood level
    if (pattern.averageMood > 7) {
      recommendations.add(MusicRecommendation(
        id: 'pattern-music-upbeat',
        title: 'Energetic Pop Mix',
        subtitle: 'Match your positive energy',
        artist: 'Various Artists',
        genre: 'Pop',
        mood: 'Energetic',
        duration: 3600,
        generatedAt: DateTime.now(),
        relevanceScore: 0.9,
        description: 'High-energy music to match your positive mood pattern',
      ));
    } else if (pattern.averageMood < 5) {
      recommendations.add(MusicRecommendation(
        id: 'pattern-music-calm',
        title: 'Calming Ambient Sounds',
        subtitle: 'Soothing music for relaxation',
        artist: 'Nature Sounds',
        genre: 'Ambient',
        mood: 'Calming',
        duration: 2400,
        generatedAt: DateTime.now(),
        relevanceScore: 0.9,
        description: 'Gentle music to help improve your mood',
      ));
    } else {
      recommendations.add(MusicRecommendation(
        id: 'pattern-music-focus',
        title: 'Lo-fi Study Mix',
        subtitle: 'Perfect for concentration',
        artist: 'Study Music',
        genre: 'Lo-fi',
        mood: 'Focused',
        duration: 3000,
        generatedAt: DateTime.now(),
        relevanceScore: 0.8,
        description: 'Instrumental music based on your focus patterns',
      ));
    }

    // Based on MBTI preferences
    if (pattern.mbtiType != null) {
      if (pattern.mbtiType!.contains('N')) { // Intuitive types
        recommendations.add(MusicRecommendation(
          id: 'pattern-music-creative',
          title: 'Creative Inspiration Playlist',
          subtitle: 'Spark your imagination',
          artist: 'Indie Artists',
          genre: 'Indie',
          mood: 'Inspirational',
          duration: 2700,
          generatedAt: DateTime.now(),
          relevanceScore: 0.8,
          description: 'Creative music for intuitive personality types',
        ));
      }
    }

    return recommendations;
  }

  /// Generate articles from user patterns
  Future<List<ArticleRecommendation>> _generateArticlesFromPattern(UserPattern pattern) async {
    final articles = <ArticleRecommendation>[];
    
    // Based on top interests
    if (pattern.topInterests.contains('productivity')) {
      articles.add(ArticleRecommendation(
        id: 'pattern-article-productivity',
        title: 'Advanced Productivity Techniques',
        subtitle: 'Based on your productivity interests',
        author: 'Productivity Expert',
        source: 'Little Brain Analysis',
        readingTimeMinutes: 7,
        tags: const ['productivity', 'efficiency'],
        generatedAt: DateTime.now(),
        relevanceScore: 0.9,
        description: 'Productivity tips tailored to your conversation patterns',
      ));
    }
    
    if (pattern.topInterests.contains('wellness')) {
      articles.add(ArticleRecommendation(
        id: 'pattern-article-wellness',
        title: 'Mindful Living Practices',
        subtitle: 'Wellness insights for you',
        author: 'Wellness Coach',
        source: 'Little Brain Analysis',
        readingTimeMinutes: 5,
        tags: const ['wellness', 'mindfulness'],
        generatedAt: DateTime.now(),
        relevanceScore: 0.9,
        description: 'Wellness advice based on your interests and mood patterns',
      ));
    }

    // Based on learning areas
    if (pattern.learningAreas.isNotEmpty) {
      articles.add(ArticleRecommendation(
        id: 'pattern-article-learning',
        title: 'Learning ${pattern.learningAreas.first} Effectively',
        subtitle: 'Accelerate your growth',
        author: 'Learning Expert',
        source: 'Little Brain Analysis',
        readingTimeMinutes: 6,
        tags: ['learning', pattern.learningAreas.first],
        generatedAt: DateTime.now(),
        relevanceScore: 0.8,
        description: 'Learning strategies for your areas of interest',
      ));
    }

    return articles;
  }

  /// Generate quote from patterns
  Future<List<DailyQuote>> _generateQuoteFromPattern(UserPattern pattern) async {
    String quote;
    String author;
    String category;
    
    if (pattern.moodTrend == 'improving') {
      quote = 'Progress, not perfection, is the goal.';
      author = 'Little Brain Wisdom';
      category = 'Growth';
    } else if (pattern.moodTrend == 'declining') {
      quote = 'Every storm runs out of rain. This too shall pass.';
      author = 'Little Brain Wisdom';
      category = 'Resilience';
    } else if (pattern.averageMood > 8) {
      quote = 'Success is not the key to happiness. Happiness is the key to success.';
      author = 'Albert Schweitzer';
      category = 'Happiness';
    } else {
      quote = 'The journey of a thousand miles begins with one step.';
      author = 'Lao Tzu';
      category = 'Motivation';
    }

    return [
      DailyQuote(
        id: 'pattern-quote-daily',
        quote: quote,
        author: author,
        category: category,
        generatedAt: DateTime.now(),
        relevanceScore: 0.9,
        explanation: 'Selected based on your mood patterns and recent experiences',
      )
    ];
  }

  /// Generate journal prompt from patterns
  Future<List<JournalPrompt>> _generateJournalFromPattern(UserPattern pattern) async {
    String prompt;
    String category;
    List<String> followUpQuestions;
    
    if (pattern.moodTrend == 'improving') {
      prompt = 'What positive changes have you noticed in yourself recently?';
      category = 'Growth Reflection';
      followUpQuestions = [
        'What actions contributed to these positive changes?',
        'How can you continue this positive momentum?'
      ];
    } else if (pattern.topInterests.contains('wellness')) {
      prompt = 'How are you taking care of your physical and mental well-being today?';
      category = 'Wellness Check';
      followUpQuestions = [
        'What wellness practices serve you best?',
        'What areas of well-being need more attention?'
      ];
    } else {
      prompt = 'What are you most grateful for in this moment?';
      category = 'Gratitude';
      followUpQuestions = [
        'How do these things impact your daily life?',
        'How can you show appreciation for these blessings?'
      ];
    }

    return [
      JournalPrompt(
        id: 'pattern-journal-daily',
        prompt: prompt,
        category: category,
        followUpQuestions: followUpQuestions,
        generatedAt: DateTime.now(),
        relevanceScore: 0.9,
      )
    ];
  }

  /// Generate content from API (only when necessary)
  Future<List<AIContent>> _generateContentFromAPI() async {
    // This would call the original API-based generation
    // But only 1 type of content at a time, rotating daily
    final today = DateTime.now();
    final contentTypeIndex = today.day % 4; // Rotate through 4 types
    
    switch (contentTypeIndex) {
      case 0:
        return await _generateMusicViaAPI();
      case 1:
        return await _generateArticlesViaAPI();
      case 2:
        return await _generateQuoteViaAPI();
      case 3:
        return await _generateJournalViaAPI();
      default:
        return [];
    }
  }

  // API usage management
  Future<bool> _canUseAPI() async {
    final usage = await _getTodayApiUsage();
    return usage < _maxApiCallsPerDay;
  }

  Future<int> _getTodayApiUsage() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = _prefs.getString(_lastApiDate);
    
    if (lastDate != today) {
      // Reset counter for new day
      await _prefs.setString(_lastApiDate, today);
      await _prefs.setInt(_apiUsageToday, 0);
      return 0;
    }
    
    return _prefs.getInt(_apiUsageToday) ?? 0;
  }

  Future<void> _incrementApiUsage() async {
    final current = await _getTodayApiUsage();
    await _prefs.setInt(_apiUsageToday, current + 1);
  }

  // Helper methods for pattern analysis
  String _calculateMoodTrend(List<dynamic> moods) {
    if (moods.length < 3) return 'stable';
    
    final recent = moods.take(7).map((m) => m.moodLevel).toList();
    final older = moods.skip(7).take(7).map((m) => m.moodLevel).toList();
    
    if (recent.isEmpty || older.isEmpty) return 'stable';
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    
    if (recentAvg > olderAvg + 0.5) return 'improving';
    if (recentAvg < olderAvg - 0.5) return 'declining';
    return 'stable';
  }

  List<String> _extractTopInterests(List<dynamic> memories) {
    final interests = <String, int>{};
    final timeWeights = <String, double>{};
    
    for (int i = 0; i < memories.take(50).length; i++) {
      final memory = memories[i];
      final recencyWeight = 1.0 - (i * 0.02); // More recent memories have higher weight
      
      for (final tag in memory.tags) {
        if (!['chat', 'conversation', 'user'].contains(tag)) {
          interests[tag] = (interests[tag] ?? 0) + 1;
          timeWeights[tag] = (timeWeights[tag] ?? 0) + recencyWeight;
        }
      }
    }
    
    // Combine frequency and recency
    final weighted = interests.entries.map((e) {
      final weightedScore = (e.value * 0.6) + (timeWeights[e.key]! * 0.4);
      return MapEntry(e.key, weightedScore);
    }).toList();
    
    weighted.sort((a, b) => b.value.compareTo(a.value));
    
    return weighted.take(5).map((e) => e.key).toList();
  }

  List<String> _extractMoodTriggers(List<dynamic> memories) {
    final triggers = <String, int>{};
    
    // Analyze patterns around mood entries
    for (final memory in memories.take(30)) {
      if (memory.type == 'mood_entry') {
        // Look for common patterns before mood entries
        final tags = memory.tags;
        for (final tag in tags) {
          if (['work', 'social', 'health', 'family', 'exercise'].any((t) => tag.contains(t))) {
            triggers[tag] = (triggers[tag] ?? 0) + 1;
          }
        }
      }
    }
    
    final sorted = triggers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(3).map((e) => e.key).toList();
  }

  List<String> _extractConversationThemes(List<dynamic> memories) {
    return _extractTopInterests(memories);
  }

  List<String> _extractLearningAreas(List<dynamic> memories) {
    final learningKeywords = ['learn', 'study', 'course', 'skill', 'development'];
    final areas = <String>[];
    
    for (final memory in memories.take(30)) {
      if (learningKeywords.any((keyword) => memory.content.toLowerCase().contains(keyword))) {
        areas.addAll(memory.tags.where((tag) => !['chat', 'conversation'].contains(tag)));
      }
    }
    
    return areas.toSet().take(3).toList();
  }

  List<String> _extractPersonalityTraits(List<dynamic> memories) {
    return ['analytical', 'creative', 'social'];
  }

  Map<int, double> _extractActiveHours(List<dynamic> memories) {
    final hours = <int, int>{};
    
    for (final memory in memories.take(100)) {
      final hour = memory.timestamp.hour;
      hours[hour] = (hours[hour] ?? 0) + 1;
    }
    
    final total = hours.values.fold(0, (a, b) => a + b);
    return hours.map((hour, count) => MapEntry(hour, count / total));
  }

  List<String> _extractContentPreferences(List<dynamic> memories) {
    return ['articles', 'music', 'quotes'];
  }

  Map<String, String> _extractResponsePatterns(List<dynamic> memories) {
    return {'engagement': 'high', 'style': 'conversational'};
  }

  // Caching methods
  Future<List<AIContent>> _getValidCachedContent() async {
    try {
      final timestamp = _prefs.getString(_cacheKeyTimestamp);
      if (timestamp == null) return [];
      
      final cacheTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(cacheTime) > _contentValidDuration) {
        return [];
      }
      
      final contentJson = _prefs.getString(_cacheKeyContent);
      if (contentJson == null) return [];
      
      final List<dynamic> contentList = jsonDecode(contentJson);
      return contentList.map((json) => _parseContentFromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _cacheContent(List<AIContent> content) async {
    try {
      final contentJson = jsonEncode(content.map((c) => _contentToJson(c)).toList());
      await _prefs.setString(_cacheKeyContent, contentJson);
      await _prefs.setString(_cacheKeyTimestamp, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Failed to cache content: $e');
    }
  }

  Future<UserPattern?> _getCachedUserPattern() async {
    try {
      final patternJson = _prefs.getString(_cacheKeyUserPattern);
      if (patternJson == null) return null;
      
      final Map<String, dynamic> json = jsonDecode(patternJson);
      final lastUpdated = DateTime.parse(json['lastUpdated']);
      
      if (DateTime.now().difference(lastUpdated) > _patternValidDuration) {
        return null;
      }
      
      return UserPattern.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheUserPattern(UserPattern pattern) async {
    try {
      final patternJson = jsonEncode(pattern.toJson());
      await _prefs.setString(_cacheKeyUserPattern, patternJson);
      debugPrint('✅ [SmartContent] User pattern cached successfully');
    } catch (e) {
      debugPrint('❌ [SmartContent] Failed to cache user pattern: $e');
    }
  }

  // API methods using OpenRouter service
  Future<List<AIContent>> _generateMusicViaAPI() async {
    try {
      final userPattern = await _buildUserPatternFromLittleBrain();
      final prompt = _buildMusicPrompt(userPattern);
      final response = await _callOpenRouterAPI(prompt, 'music');
      return _parseMusicResponse(response);
    } catch (e) {
      debugPrint('🚨 [SmartContent] Music API generation failed: $e');
      return [];
    }
  }

  Future<List<AIContent>> _generateArticlesViaAPI() async {
    try {
      final userPattern = await _buildUserPatternFromLittleBrain();
      final prompt = _buildArticlePrompt(userPattern);
      final response = await _callOpenRouterAPI(prompt, 'article');
      return _parseArticleResponse(response);
    } catch (e) {
      debugPrint('🚨 [SmartContent] Article API generation failed: $e');
      return [];
    }
  }

  Future<List<AIContent>> _generateQuoteViaAPI() async {
    try {
      final userPattern = await _buildUserPatternFromLittleBrain();
      final prompt = _buildQuotePrompt(userPattern);
      final response = await _callOpenRouterAPI(prompt, 'quote');
      return _parseQuoteResponse(response);
    } catch (e) {
      debugPrint('🚨 [SmartContent] Quote API generation failed: $e');
      return [];
    }
  }

  Future<List<AIContent>> _generateJournalViaAPI() async {
    try {
      final userPattern = await _buildUserPatternFromLittleBrain();
      final prompt = _buildJournalPrompt(userPattern);
      final response = await _callOpenRouterAPI(prompt, 'journal');
      return _parseJournalResponse(response);
    } catch (e) {
      debugPrint('🚨 [SmartContent] Journal API generation failed: $e');
      return [];
    }
  }

  // OpenRouter API integration methods
  Future<String> _callOpenRouterAPI(String prompt, String contentType) async {
    try {
      final request = ChatCompletionRequest(
        model: 'anthropic/claude-3.5-sonnet', // Efficient model for content generation
        messages: [
          ChatMessage(role: 'system', content: _getSystemPrompt(contentType)),
          ChatMessage(role: 'user', content: prompt),
        ],
        maxTokens: 1500,
        temperature: 0.7,
      );

      final response = await _openRouterService.createChatCompletion(request);
      return response.choices.first.message.content;
    } catch (e) {
      debugPrint('🚨 [OpenRouter] API call failed: $e');
      throw Exception('OpenRouter API call failed: $e');
    }
  }

  String _getSystemPrompt(String contentType) {
    switch (contentType) {
      case 'music':
        return '''You are a music recommendation AI. Generate personalized music recommendations in JSON format.
Return a JSON array with objects containing: id, title, subtitle, artist, genre, mood, duration (seconds), description.
Focus on the user's current mood and preferences. Be specific and realistic.''';
      
      case 'article':
        return '''You are an article recommendation AI. Generate personalized article recommendations in JSON format.
Return a JSON array with objects containing: id, title, subtitle, author, source, readingTimeMinutes, tags (array), description.
Focus on the user's interests and learning areas. Be specific and realistic.''';
      
      case 'quote':
        return '''You are a motivational quote AI. Generate personalized daily quotes in JSON format.
Return a JSON object containing: id, quote, author, category, explanation.
Match the user's current mood and situation. Be inspiring and relevant.''';
      
      case 'journal':
        return '''You are a journaling prompt AI. Generate personalized journal prompts in JSON format.
Return a JSON object containing: id, prompt, category, followUpQuestions (array).
Create thoughtful prompts based on the user's patterns and needs.''';
      
      default:
        return 'You are a helpful Assistant that generates personalized content.';
    }
  }

  // Prompt building methods
  String _buildMusicPrompt(UserPattern pattern) {
    final moodDesc = pattern.averageMood > 7 ? 'upbeat and energetic' : 
                     pattern.averageMood < 5 ? 'calming and soothing' : 'focused and balanced';
    
    return '''Generate 2-3 music recommendations for a user with:
- Current mood level: ${pattern.averageMood}/10 (${pattern.moodTrend})
- Preferred mood: $moodDesc
- Top interests: ${pattern.topInterests.take(3).join(', ')}
- MBTI type: ${pattern.mbtiType ?? 'Unknown'}
- Active hours: ${_getActiveHoursDescription(pattern.activeHours)}

Consider their personality and current emotional state. Make recommendations specific and engaging.''';
  }

  String _buildArticlePrompt(UserPattern pattern) {
    return '''Generate 2-3 article recommendations for a user with:
- Top interests: ${pattern.topInterests.join(', ')}
- Learning areas: ${pattern.learningAreas.join(', ')}
- MBTI type: ${pattern.mbtiType ?? 'Unknown'}
- Mental health level: ${pattern.mentalHealthLevel ?? 'Unknown'}
- Conversation themes: ${pattern.conversationThemes.take(3).join(', ')}

Focus on their growth areas and current interests. Make articles practical and actionable.''';
  }

  String _buildQuotePrompt(UserPattern pattern) {
    return '''Generate a personalized daily quote for a user with:
- Current mood: ${pattern.averageMood}/10 (trend: ${pattern.moodTrend})
- Top interests: ${pattern.topInterests.take(3).join(', ')}
- Personality traits: ${pattern.personalityTraits.join(', ')}
- Mood triggers: ${pattern.commonMoodTriggers.join(', ')}

Create an inspiring quote that resonates with their current situation and personality.''';
  }

  String _buildJournalPrompt(UserPattern pattern) {
    return '''Generate a personalized journal prompt for a user with:
- Mood trend: ${pattern.moodTrend} (current: ${pattern.averageMood}/10)
- Learning areas: ${pattern.learningAreas.join(', ')}
- Recent themes: ${pattern.conversationThemes.take(3).join(', ')}
- Personality traits: ${pattern.personalityTraits.join(', ')}

Create a thoughtful prompt that encourages self-reflection and growth.''';
  }

  // Response parsing methods
  List<AIContent> _parseMusicResponse(String response) {
    try {
      final data = jsonDecode(response);
      final List<dynamic> items = data is List ? data : [data];
      
      return items.map((item) => MusicRecommendation(
        id: item['id'] ?? 'api-music-${DateTime.now().millisecondsSinceEpoch}',
        title: item['title'] ?? 'Generated Music',
        subtitle: item['subtitle'] ?? 'Personalized recommendation',
        artist: item['artist'] ?? 'Various Artists',
        genre: item['genre'] ?? 'Mixed',
        mood: item['mood'] ?? 'Neutral',
        duration: item['duration'] ?? 3600,
        description: item['description'],
        generatedAt: DateTime.now(),
        relevanceScore: 0.9,
      )).cast<AIContent>().toList();
    } catch (e) {
      debugPrint('🚨 [Parser] Music response parsing failed: $e');
      return [];
    }
  }

  List<AIContent> _parseArticleResponse(String response) {
    try {
      final data = jsonDecode(response);
      final List<dynamic> items = data is List ? data : [data];
      
      return items.map((item) => ArticleRecommendation(
        id: item['id'] ?? 'api-article-${DateTime.now().millisecondsSinceEpoch}',
        title: item['title'] ?? 'Generated Article',
        subtitle: item['subtitle'] ?? 'Personalized recommendation',
        author: item['author'] ?? 'AI Generated',
        source: item['source'] ?? 'Smart Content',
        readingTimeMinutes: item['readingTimeMinutes'] ?? 5,
        tags: List<String>.from(item['tags'] ?? ['ai-generated']),
        description: item['description'],
        generatedAt: DateTime.now(),
        relevanceScore: 0.9,
      )).cast<AIContent>().toList();
    } catch (e) {
      debugPrint('🚨 [Parser] Article response parsing failed: $e');
      return [];
    }
  }

  List<AIContent> _parseQuoteResponse(String response) {
    try {
      final data = jsonDecode(response);
      
      return [DailyQuote(
        id: data['id'] ?? 'api-quote-${DateTime.now().millisecondsSinceEpoch}',
        quote: data['quote'] ?? 'Every moment is a fresh beginning.',
        author: data['author'] ?? 'AI Wisdom',
        category: data['category'] ?? 'Inspiration',
        explanation: data['explanation'] ?? 'Personalized for your current journey',
        generatedAt: DateTime.now(),
        relevanceScore: 0.9,
      )];
    } catch (e) {
      debugPrint('🚨 [Parser] Quote response parsing failed: $e');
      return [];
    }
  }

  List<AIContent> _parseJournalResponse(String response) {
    try {
      final data = jsonDecode(response);
      
      return [JournalPrompt(
        id: data['id'] ?? 'api-journal-${DateTime.now().millisecondsSinceEpoch}',
        prompt: data['prompt'] ?? 'What are you grateful for today?',
        category: data['category'] ?? 'Reflection',
        followUpQuestions: List<String>.from(data['followUpQuestions'] ?? ['How does this make you feel?']),
        generatedAt: DateTime.now(),
        relevanceScore: 0.9,
      )];
    } catch (e) {
      debugPrint('🚨 [Parser] Journal response parsing failed: $e');
      return [];
    }
  }

  // Helper methods
  String _getActiveHoursDescription(Map<int, double> activeHours) {
    if (activeHours.isEmpty) return 'varied';
    
    final sortedHours = activeHours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topHour = sortedHours.first.key;
    if (topHour >= 6 && topHour <= 11) return 'morning person';
    if (topHour >= 12 && topHour <= 17) return 'afternoon active';
    if (topHour >= 18 && topHour <= 22) return 'evening person';
    return 'night owl';
  }

  // Metrics and analytics methods
  Future<void> _updateMetrics(String metric, int value) async {
    try {
      final currentValue = _prefs.getInt('metrics_$metric') ?? 0;
      await _prefs.setInt('metrics_$metric', currentValue + value);
    } catch (e) {
      debugPrint('❌ [Metrics] Failed to update $metric: $e');
    }
  }

  Future<void> _logPerformanceMetrics(String source, int durationMs, int itemCount) async {
    try {
      final metrics = ContentMetrics(
        source: source,
        durationMs: durationMs,
        itemCount: itemCount,
        timestamp: DateTime.now(),
      );
      
      final metricsKey = 'performance_metrics_${DateTime.now().toIso8601String().split('T')[0]}';
      final existing = _prefs.getStringList(metricsKey) ?? [];
      existing.add(jsonEncode(metrics.toJson()));
      
      // Keep only last 100 entries
      if (existing.length > 100) {
        existing.removeRange(0, existing.length - 100);
      }
      
      await _prefs.setStringList(metricsKey, existing);
      debugPrint('📊 [Metrics] Logged: $source took ${durationMs}ms for $itemCount items');
    } catch (e) {
      debugPrint('❌ [Metrics] Failed to log performance: $e');
    }
  }

  Future<void> _logError(String operation, String error, int durationMs) async {
    try {
      final errorData = {
        'operation': operation,
        'error': error,
        'durationMs': durationMs,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final errorKey = 'error_logs_${DateTime.now().toIso8601String().split('T')[0]}';
      final existing = _prefs.getStringList(errorKey) ?? [];
      existing.add(jsonEncode(errorData));
      
      // Keep only last 50 errors
      if (existing.length > 50) {
        existing.removeRange(0, existing.length - 50);
      }
      
      await _prefs.setStringList(errorKey, existing);
      debugPrint('🚨 [Error] Logged: $operation failed in ${durationMs}ms - $error');
    } catch (e) {
      debugPrint('❌ [Error] Failed to log error: $e');
    }
  }

  // Debug and monitoring methods
  Future<void> printAnalyticsSummary() async {
    try {
      final summary = await getAnalyticsSummary();
      debugPrint(summary.toString());
    } catch (e) {
      debugPrint('❌ [Debug] Failed to print analytics: $e');
    }
  }

  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final summary = await getAnalyticsSummary();
      final cacheValid = await _getValidCachedContent();
      final patternValid = await _getCachedUserPattern();
      final apiUsage = await _getTodayApiUsage();

      return {
        'status': 'healthy',
        'cache_status': cacheValid.isNotEmpty ? 'valid' : 'empty',
        'pattern_status': patternValid != null ? 'valid' : 'expired',
        'api_usage': '$apiUsage/$_maxApiCallsPerDay',
        'performance': {
          'cache_hit_rate': summary.cacheHitRate,
          'avg_generation_time': summary.averageGenerationTime,
          'api_savings_rate': summary.apiSavingsRate,
        },
        'metrics': summary.toJson(),
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ [Health] Failed to get system health: $e');
      return {
        'status': 'error',
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<void> warmUpCache() async {
    try {
      debugPrint('🔥 [WarmUp] Starting cache warm-up...');
      
      // Generate fresh content
      final content = await _generateContentFromLittleBrain();
      if (content.isNotEmpty) {
        await _cacheContent(content);
        debugPrint('✅ [WarmUp] Cache warmed with ${content.length} items');
      }
      
      // Pre-build user pattern
      await _buildUserPatternFromLittleBrain();
      debugPrint('✅ [WarmUp] User pattern updated');
      
      debugPrint('🔥 [WarmUp] Cache warm-up completed');
    } catch (e) {
      debugPrint('❌ [WarmUp] Cache warm-up failed: $e');
    }
  }

  // Test methods for debugging
  Future<void> testContentGeneration() async {
    try {
      debugPrint('🧪 [Test] Testing content generation...');
      
      final stopwatch = Stopwatch()..start();
      final content = await getSmartContent();
      stopwatch.stop();
      
      debugPrint('✅ [Test] Generated ${content.length} items in ${stopwatch.elapsedMilliseconds}ms');
      
      for (final item in content) {
        debugPrint('   - ${item.runtimeType}: ${item.id}');
      }
    } catch (e) {
      debugPrint('❌ [Test] Content generation test failed: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      debugPrint('🧹 [Clear] Clearing all cache...');
      
      await _prefs.remove(_cacheKeyContent);
      await _prefs.remove(_cacheKeyTimestamp);
      await _prefs.remove(_cacheKeyUserPattern);
      
      // Reset API usage
      await _prefs.remove(_apiUsageToday);
      await _prefs.remove(_lastApiDate);
      
      debugPrint('✅ [Clear] All cache cleared');
    } catch (e) {
      debugPrint('❌ [Clear] Failed to clear cache: $e');
    }
  }

  // Content parsing methods
  AIContent _parseContentFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    
    switch (type) {
      case 'music':
        return MusicRecommendation(
          id: json['id'],
          title: json['title'],
          subtitle: json['subtitle'],
          artist: json['artist'],
          genre: json['genre'],
          mood: json['mood'],
          duration: json['duration'],
          description: json['description'],
          generatedAt: DateTime.parse(json['generatedAt']),
          relevanceScore: json['relevanceScore'].toDouble(),
        );
      case 'article':
        return ArticleRecommendation(
          id: json['id'],
          title: json['title'],
          subtitle: json['subtitle'],
          author: json['author'],
          source: json['source'],
          readingTimeMinutes: json['readingTimeMinutes'],
          tags: List<String>.from(json['tags']),
          description: json['description'],
          generatedAt: DateTime.parse(json['generatedAt']),
          relevanceScore: json['relevanceScore'].toDouble(),
        );
      case 'quote':
        return DailyQuote(
          id: json['id'],
          quote: json['quote'],
          author: json['author'],
          category: json['category'],
          explanation: json['explanation'],
          generatedAt: DateTime.parse(json['generatedAt']),
          relevanceScore: json['relevanceScore'].toDouble(),
        );
      case 'journal':
        return JournalPrompt(
          id: json['id'],
          prompt: json['prompt'],
          category: json['category'],
          followUpQuestions: List<String>.from(json['followUpQuestions']),
          generatedAt: DateTime.parse(json['generatedAt']),
          relevanceScore: json['relevanceScore'].toDouble(),
        );
      default:
        throw Exception('Unknown content type: $type');
    }
  }

  Map<String, dynamic> _contentToJson(AIContent content) {
    final baseJson = {
      'id': content.id,
      'generatedAt': content.generatedAt.toIso8601String(),
      'relevanceScore': content.relevanceScore,
    };

    if (content is MusicRecommendation) {
      return {
        ...baseJson,
        'type': 'music',
        'title': content.title,
        'subtitle': content.subtitle,
        'artist': content.artist,
        'genre': content.genre,
        'mood': content.mood,
        'duration': content.duration,
        'description': content.description,
      };
    } else if (content is ArticleRecommendation) {
      return {
        ...baseJson,
        'type': 'article',
        'title': content.title,
        'subtitle': content.subtitle,
        'author': content.author,
        'source': content.source,
        'readingTimeMinutes': content.readingTimeMinutes,
        'tags': content.tags,
        'description': content.description,
      };
    } else if (content is DailyQuote) {
      return {
        ...baseJson,
        'type': 'quote',
        'quote': content.quote,
        'author': content.author,
        'category': content.category,
        'explanation': content.explanation,
      };
    } else if (content is JournalPrompt) {
      return {
        ...baseJson,
        'type': 'journal',
        'prompt': content.prompt,
        'category': content.category,
        'followUpQuestions': content.followUpQuestions,
      };
    }

    throw Exception('Unknown content type: ${content.runtimeType}');
  }

  // Fallback content method
  List<AIContent> _getFallbackContent() {
    return [
      MusicRecommendation(
        id: 'fallback-music-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Lo-fi Study Mix',
        subtitle: 'Perfect for focus and relaxation',
        artist: 'Various Artists',
        genre: 'Lo-fi',
        mood: 'Calm',
        duration: 3600,
        description: 'A collection of soothing lo-fi beats perfect for studying or relaxing',
        generatedAt: DateTime.now(),
        relevanceScore: 0.7,
      ),
      ArticleRecommendation(
        id: 'fallback-article-${DateTime.now().millisecondsSinceEpoch}',
        title: 'The Power of Mindfulness',
        subtitle: 'Transform your daily life with presence',
        author: 'Mindfulness Expert',
        source: 'Wellness Journal',
        readingTimeMinutes: 5,
        tags: const ['mindfulness', 'wellness', 'mental-health'],
        description: 'Discover how mindfulness can improve your focus, reduce stress, and enhance well-being',
        generatedAt: DateTime.now(),
        relevanceScore: 0.7,
      ),
      DailyQuote(
        id: 'fallback-quote-${DateTime.now().millisecondsSinceEpoch}',
        quote: 'The journey of a thousand miles begins with one step.',
        author: 'Lao Tzu',
        category: 'Motivation',
        explanation: 'A reminder that all great achievements start with small actions',
        generatedAt: DateTime.now(),
        relevanceScore: 0.7,
      ),
      JournalPrompt(
        id: 'fallback-journal-${DateTime.now().millisecondsSinceEpoch}',
        prompt: 'What three things am I grateful for today?',
        category: 'Gratitude',
        followUpQuestions: const [
          'How do these things impact my daily life?',
          'How can I show appreciation for these blessings?'
        ],
        generatedAt: DateTime.now(),
        relevanceScore: 0.7,
      ),
    ];
  }

  // Analytics methods
  Future<AnalyticsSummary> getAnalyticsSummary() async {
    try {
      final totalRequests = _prefs.getInt('metrics_total_requests') ?? 0;
      final cacheHits = _prefs.getInt('metrics_cache_hits') ?? 0;
      final littleBrainGenerated = _prefs.getInt('metrics_little_brain_generated') ?? 0;
      final apiCalls = _prefs.getInt('metrics_api_calls') ?? 0;
      final fallbackUsed = _prefs.getInt('metrics_fallback_used') ?? 0;
      final errors = _prefs.getInt('metrics_errors') ?? 0;
      final totalGenerationTime = _prefs.getInt('metrics_total_generation_time') ?? 0;

      final cacheHitRate = totalRequests > 0 ? (cacheHits / totalRequests) * 100 : 0.0;
      final averageGenerationTime = totalRequests > 0 ? totalGenerationTime / totalRequests : 0.0;
      final apiSavingsRate = totalRequests > 0 ? ((totalRequests - apiCalls) / totalRequests) * 100 : 0.0;

      return AnalyticsSummary(
        totalRequests: totalRequests,
        cacheHits: cacheHits,
        littleBrainGenerated: littleBrainGenerated,
        apiCalls: apiCalls,
        fallbackUsed: fallbackUsed,
        errors: errors,
        cacheHitRate: cacheHitRate,
        averageGenerationTime: averageGenerationTime,
        apiSavingsRate: apiSavingsRate,
      );
    } catch (e) {
      debugPrint('❌ [Analytics] Failed to get summary: $e');
      return AnalyticsSummary.empty();
    }
  }

  // Clear analytics data
  Future<void> clearAnalytics() async {
    try {
      final keys = _prefs.getKeys().where((key) => key.startsWith('metrics_') || key.startsWith('performance_') || key.startsWith('error_'));
      for (final key in keys) {
        await _prefs.remove(key);
      }
      debugPrint('✅ [Analytics] Cleared all analytics data');
    } catch (e) {
      debugPrint('❌ [Analytics] Failed to clear data: $e');
    }
  }
}

/// User pattern model for Little Brain analysis
class UserPattern {
  final double averageMood;
  final String moodTrend;
  final List<String> commonMoodTriggers;
  final List<String> topInterests;
  final List<String> conversationThemes;
  final List<String> learningAreas;
  final String? mbtiType;
  final String? mentalHealthLevel;
  final List<String> personalityTraits;
  final Map<int, double> activeHours;
  final List<String> preferredContentTypes;
  final Map<String, String> responsePatterns;
  final DateTime lastUpdated;

  UserPattern({
    required this.averageMood,
    required this.moodTrend,
    required this.commonMoodTriggers,
    required this.topInterests,
    required this.conversationThemes,
    required this.learningAreas,
    this.mbtiType,
    this.mentalHealthLevel,
    required this.personalityTraits,
    required this.activeHours,
    required this.preferredContentTypes,
    required this.responsePatterns,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'averageMood': averageMood,
      'moodTrend': moodTrend,
      'commonMoodTriggers': commonMoodTriggers,
      'topInterests': topInterests,
      'conversationThemes': conversationThemes,
      'learningAreas': learningAreas,
      'mbtiType': mbtiType,
      'mentalHealthLevel': mentalHealthLevel,
      'personalityTraits': personalityTraits,
      'activeHours': activeHours.map((k, v) => MapEntry(k.toString(), v)),
      'preferredContentTypes': preferredContentTypes,
      'responsePatterns': responsePatterns,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserPattern.fromJson(Map<String, dynamic> json) {
    return UserPattern(
      averageMood: json['averageMood'].toDouble(),
      moodTrend: json['moodTrend'],
      commonMoodTriggers: List<String>.from(json['commonMoodTriggers']),
      topInterests: List<String>.from(json['topInterests']),
      conversationThemes: List<String>.from(json['conversationThemes']),
      learningAreas: List<String>.from(json['learningAreas']),
      mbtiType: json['mbtiType'],
      mentalHealthLevel: json['mentalHealthLevel'],
      personalityTraits: List<String>.from(json['personalityTraits']),
      activeHours: Map<int, double>.from(json['activeHours'].map((k, v) => MapEntry(int.parse(k), v.toDouble()))),
      preferredContentTypes: List<String>.from(json['preferredContentTypes']),
      responsePatterns: Map<String, String>.from(json['responsePatterns']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

/// Content generation metrics model
class ContentMetrics {
  final String source;
  final int durationMs;
  final int itemCount;
  final DateTime timestamp;

  ContentMetrics({
    required this.source,
    required this.durationMs,
    required this.itemCount,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'durationMs': durationMs,
      'itemCount': itemCount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ContentMetrics.fromJson(Map<String, dynamic> json) {
    return ContentMetrics(
      source: json['source'],
      durationMs: json['durationMs'],
      itemCount: json['itemCount'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Analytics summary model
class AnalyticsSummary {
  final int totalRequests;
  final int cacheHits;
  final int littleBrainGenerated;
  final int apiCalls;
  final int fallbackUsed;
  final int errors;
  final double cacheHitRate;
  final double averageGenerationTime;
  final double apiSavingsRate;

  AnalyticsSummary({
    required this.totalRequests,
    required this.cacheHits,
    required this.littleBrainGenerated,
    required this.apiCalls,
    required this.fallbackUsed,
    required this.errors,
    required this.cacheHitRate,
    required this.averageGenerationTime,
    required this.apiSavingsRate,
  });

  factory AnalyticsSummary.empty() {
    return AnalyticsSummary(
      totalRequests: 0,
      cacheHits: 0,
      littleBrainGenerated: 0,
      apiCalls: 0,
      fallbackUsed: 0,
      errors: 0,
      cacheHitRate: 0.0,
      averageGenerationTime: 0.0,
      apiSavingsRate: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRequests': totalRequests,
      'cacheHits': cacheHits,
      'littleBrainGenerated': littleBrainGenerated,
      'apiCalls': apiCalls,
      'fallbackUsed': fallbackUsed,
      'errors': errors,
      'cacheHitRate': cacheHitRate,
      'averageGenerationTime': averageGenerationTime,
      'apiSavingsRate': apiSavingsRate,
    };
  }

  @override
  String toString() {
    return '''
📊 Smart Content Analytics Summary:
├─ Total Requests: $totalRequests
├─ Cache Hits: $cacheHits (${cacheHitRate.toStringAsFixed(1)}%)
├─ Little Brain Generated: $littleBrainGenerated
├─ API Calls: $apiCalls
├─ Fallback Used: $fallbackUsed
├─ Errors: $errors
├─ Avg Generation Time: ${averageGenerationTime.toStringAsFixed(1)}ms
└─ API Savings Rate: ${apiSavingsRate.toStringAsFixed(1)}%
    ''';
  }
}
