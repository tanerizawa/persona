import 'package:equatable/equatable.dart';

/// AI-curated content for home dashboard
class AIContent extends Equatable {
  final String id;
  final String type; // 'music', 'article', 'quote', 'journal_prompt'
  final String title;
  final String subtitle;
  final String? description;
  final String? imageUrl;
  final String? sourceUrl;
  final Map<String, dynamic> metadata;
  final DateTime generatedAt;
  final double relevanceScore; // 0.0 to 1.0

  const AIContent({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.description,
    this.imageUrl,
    this.sourceUrl,
    this.metadata = const {},
    required this.generatedAt,
    required this.relevanceScore,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        subtitle,
        description,
        imageUrl,
        sourceUrl,
        metadata,
        generatedAt,
        relevanceScore,
      ];
}

/// Music recommendation from AI
class MusicRecommendation extends AIContent {
  final String artist;
  final String genre;
  final String mood;
  final int duration; // in seconds

  const MusicRecommendation({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.artist,
    required this.genre,
    required this.mood,
    required this.duration,
    super.description,
    super.imageUrl,
    super.sourceUrl,
    super.metadata = const {},
    required super.generatedAt,
    required super.relevanceScore,
  }) : super(type: 'music');

  @override
  List<Object?> get props => [...super.props, artist, genre, mood, duration];
}

/// Article recommendation from AI
class ArticleRecommendation extends AIContent {
  final String author;
  final String source;
  final int readingTimeMinutes;
  final List<String> tags;

  const ArticleRecommendation({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.author,
    required this.source,
    required this.readingTimeMinutes,
    required this.tags,
    super.description,
    super.imageUrl,
    super.sourceUrl,
    super.metadata = const {},
    required super.generatedAt,
    required super.relevanceScore,
  }) : super(type: 'article');

  @override
  List<Object?> get props => [...super.props, author, source, readingTimeMinutes, tags];
}

/// Daily quote from AI
class DailyQuote extends AIContent {
  final String quote;
  final String author;
  final String category;
  final String? explanation;

  const DailyQuote({
    required super.id,
    required this.quote,
    required this.author,
    required this.category,
    this.explanation,
    super.metadata = const {},
    required super.generatedAt,
    required super.relevanceScore,
  }) : super(
          type: 'quote',
          title: quote,
          subtitle: author,
        );

  @override
  List<Object?> get props => [...super.props, quote, author, category, explanation];
}

/// Journal prompt from AI
class JournalPrompt extends AIContent {
  final String prompt;
  final String category;
  final List<String> followUpQuestions;

  const JournalPrompt({
    required super.id,
    required this.prompt,
    required this.category,
    required this.followUpQuestions,
    super.metadata = const {},
    required super.generatedAt,
    required super.relevanceScore,
  }) : super(
          type: 'journal_prompt',
          title: prompt,
          subtitle: category,
        );

  @override
  List<Object?> get props => [...super.props, prompt, category, followUpQuestions];
}

/// Personalization context for AI content generation
class PersonalizationContext extends Equatable {
  final double? currentMoodLevel; // 1-10 from recent mood entries
  final String? dominantMoodTrend; // 'improving', 'declining', 'stable'
  final String? mbtiType; // Latest MBTI result
  final String? currentMentalHealthLevel; // From latest BDI
  final List<String> recentInterests; // From conversation topics
  final List<String> lifeAreaFocus; // From life tree analysis
  final Map<String, dynamic> additionalContext;

  const PersonalizationContext({
    this.currentMoodLevel,
    this.dominantMoodTrend,
    this.mbtiType,
    this.currentMentalHealthLevel,
    this.recentInterests = const [],
    this.lifeAreaFocus = const [],
    this.additionalContext = const {},
  });

  @override
  List<Object?> get props => [
        currentMoodLevel,
        dominantMoodTrend,
        mbtiType,
        currentMentalHealthLevel,
        recentInterests,
        lifeAreaFocus,
        additionalContext,
      ];
}

/// Content generation request for AI
class ContentGenerationRequest extends Equatable {
  final String contentType; // 'music', 'article', 'quote', 'journal_prompt'
  final PersonalizationContext context;
  final int maxItems;
  final DateTime requestedAt;

  const ContentGenerationRequest({
    required this.contentType,
    required this.context,
    this.maxItems = 3,
    required this.requestedAt,
  });

  @override
  List<Object> get props => [contentType, context, maxItems, requestedAt];
}
