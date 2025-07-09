import 'package:injectable/injectable.dart';
import '../../../little_brain/domain/usecases/little_brain_local_usecases.dart';
import '../../../psychology/domain/usecases/psychology_testing_usecases.dart';
import '../../../growth/domain/usecases/mood_tracking_usecases.dart';

@injectable
class SmartPromptBuilderService {
  final CreateAIContextLocalUseCase _createAIContext;
  final GetRelevantMemoriesLocalUseCase _getRelevantMemories;
  final PsychologyTestingUseCases _psychologyTesting;
  final MoodTrackingUseCases _moodTracking;

  // Cache untuk menghindari pembuatan prompt berulang
  String? _cachedPrompt;
  String? _cachedUserMessage;
  DateTime? _lastPromptGeneration;
  static const _promptCacheDuration = Duration(minutes: 5);

  SmartPromptBuilderService(
    this._createAIContext,
    this._getRelevantMemories,
    this._psychologyTesting,
    this._moodTracking,
  );

  /// Build smart, efficient prompt using Little Brain intelligence
  Future<String> buildSmartPrompt(String userMessage, {String? conversationId}) async {
    try {
      // Check cache first
      if (_cachedPrompt != null &&
          _cachedUserMessage == userMessage &&
          _lastPromptGeneration != null &&
          DateTime.now().difference(_lastPromptGeneration!) < _promptCacheDuration) {
        return _cachedPrompt!;
      }

      final promptBuilder = StringBuffer();
      
      // Core personality - always included but minimal
      promptBuilder.writeln('You are Persona, a caring AI companion focused on personal growth.');
      
      // Get Little Brain's intelligent context
      final brainContext = await _getBrainContext(userMessage);
      if (brainContext.isNotEmpty) {
        promptBuilder.writeln('\nCONTEXT FROM MEMORY:');
        promptBuilder.writeln(brainContext);
      }

      // Get critical psychological context only if relevant
      final psychContext = await _getRelevantPsychContext(userMessage);
      if (psychContext.isNotEmpty) {
        promptBuilder.writeln('\nUSER CONTEXT:');
        promptBuilder.writeln(psychContext);
      }

      // Response guidelines - concise version with strict formatting rules
      promptBuilder.writeln('\nRESPONSE STYLE:');
      promptBuilder.writeln('- Be warm, personal, and naturally conversational');
      promptBuilder.writeln('- Reference relevant past experiences when helpful');
      promptBuilder.writeln('- Support their personal growth journey');
      promptBuilder.writeln('- Use Indonesian naturally when appropriate');
      promptBuilder.writeln('- NEVER use emotional stage directions in parentheses');
      
      promptBuilder.writeln('\nCRITICAL FORMATTING RULES:');
      promptBuilder.writeln('- NEVER use numbered lists (1. 2. 3.)');
      promptBuilder.writeln('- NEVER use bullet points (•, -, *)');
      promptBuilder.writeln('- NEVER use "tips", "cara", "langkah", "berikut ini:"');
      promptBuilder.writeln('- Write in natural paragraph format only');
      promptBuilder.writeln('- Keep responses conversational and flowing');
      promptBuilder.writeln('- Maximum 2 paragraphs total (320 characters max)');
      promptBuilder.writeln('- Each paragraph should be naturally readable');
      
      promptBuilder.writeln('\nBUBBLE SPLITTING RULES:');
      promptBuilder.writeln('- For longer responses (>160 chars), split into 2 paragraphs using <span>');
      promptBuilder.writeln('- Format: "First paragraph <span> Second paragraph"');
      promptBuilder.writeln('- First paragraph: empathy/understanding (max 160 chars)');
      promptBuilder.writeln('- Second paragraph: advice/question/technique (max 160 chars)');
      promptBuilder.writeln('- Example: "Aku paham perasaanmu saat ini sangat berat dan melelahkan. <span> Bagaimana kalau kita coba teknik pernapasan sederhana untuk menenangkan pikiran?"');
      promptBuilder.writeln('- For short responses (<160 chars): NO <span>, use single paragraph');
      promptBuilder.writeln('- ALWAYS ensure each paragraph is complete and makes sense alone');

      final finalPrompt = promptBuilder.toString();
      
      // Cache the result
      _cachedPrompt = finalPrompt;
      _cachedUserMessage = userMessage;
      _lastPromptGeneration = DateTime.now();
      
      return finalPrompt;
    } catch (e) {
      // Fallback to minimal prompt
      return _getMinimalPrompt();
    }
  }

  /// Get intelligent context from Little Brain based on user message
  Future<String> _getBrainContext(String userMessage) async {
    try {
      // Use Little Brain to analyze the message and get relevant context
      final aiContext = await _createAIContext.call(userMessage);
      
      // Get most relevant memories (limited to 3 to save tokens)
      final relevantMemories = await _getRelevantMemories.call(userMessage, limit: 3);
      
      if (relevantMemories.isEmpty && aiContext.contains('No previous context')) {
        return '';
      }

      final contextBuilder = StringBuffer();
      
      // Add AI-generated context
      if (!aiContext.contains('No previous context')) {
        contextBuilder.writeln('- ${_summarizeContext(aiContext)}');
      }

      // Add most relevant memories in condensed format
      for (final memory in relevantMemories) {
        final summary = _summarizeMemory(memory.content, memory.source);
        if (summary.isNotEmpty) {
          contextBuilder.writeln('- $summary');
        }
      }

      return contextBuilder.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// Get relevant psychological context only when needed
  Future<String> _getRelevantPsychContext(String userMessage) async {
    try {
      final contextNeeded = _isPersonalContextNeeded(userMessage);
      if (!contextNeeded) return '';

      final contextBuilder = StringBuffer();
      
      // Time context (always relevant for personal touch)
      final now = DateTime.now();
      final timeOfDay = now.hour < 12 ? 'pagi' : 
                       now.hour < 15 ? 'siang' : 
                       now.hour < 18 ? 'sore' : 'malam';
      contextBuilder.writeln('Waktu: $timeOfDay');

      // Get critical psychological data with timeout
      try {
        final psychData = await _psychologyTesting.getPsychologyAnalytics()
            .timeout(const Duration(seconds: 1));
            
        if (psychData.latestMBTI != null) {
          final mbti = psychData.latestMBTI!;
          contextBuilder.writeln('MBTI: ${mbti.personalityType} (${_getMBTIHint(mbti.personalityType)})');
        }

        if (psychData.latestBDI != null && _isMentalHealthContextNeeded(userMessage)) {
          final bdi = psychData.latestBDI!;
          contextBuilder.writeln('Mental: ${bdi.level.indonesianDescription}');
        }
      } catch (e) {
        // Skip if takes too long
      }

      // Current mood only if relevant
      if (_isMoodContextNeeded(userMessage)) {
        try {
          final moods = await _moodTracking.getRecentMoodEntries(limit: 1)
              .timeout(const Duration(milliseconds: 500));
          if (moods.isNotEmpty) {
            final mood = moods.first.moodLevel;
            contextBuilder.writeln('Mood: ${mood.toStringAsFixed(1)}/10');
          }
        } catch (e) {
          // Skip if takes too long
        }
      }

      return contextBuilder.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// Determine if personal context is needed based on message content
  bool _isPersonalContextNeeded(String message) {
    final personalIndicators = [
      'bagaimana', 'gimana', 'feeling', 'merasa', 'mood', 'suasana hati',
      'personality', 'kepribadian', 'saya', 'aku', 'me', 'my', 'advice',
      'saran', 'help', 'bantuan', 'guidance', 'guidance'
    ];
    
    final lowerMessage = message.toLowerCase();
    return personalIndicators.any((indicator) => lowerMessage.contains(indicator));
  }

  /// Check if mental health context is relevant
  bool _isMentalHealthContextNeeded(String message) {
    final mentalHealthIndicators = [
      'stress', 'cemas', 'anxiety', 'depresi', 'sedih', 'down', 'worry',
      'khawatir', 'overwhelmed', 'burnout', 'tired', 'lelah', 'help',
      'bantuan', 'support', 'dukungan'
    ];
    
    final lowerMessage = message.toLowerCase();
    return mentalHealthIndicators.any((indicator) => lowerMessage.contains(indicator));
  }

  /// Check if mood context is relevant
  bool _isMoodContextNeeded(String message) {
    final moodIndicators = [
      'feeling', 'merasa', 'mood', 'suasana', 'emosi', 'emotion',
      'happy', 'senang', 'sad', 'sedih', 'angry', 'marah', 'excited',
      'antusias', 'calm', 'tenang', 'today', 'hari ini', 'sekarang'
    ];
    
    final lowerMessage = message.toLowerCase();
    return moodIndicators.any((indicator) => lowerMessage.contains(indicator));
  }

  /// Summarize AI context to save tokens
  String _summarizeContext(String context) {
    if (context.length <= 100) return context;
    
    // Extract key points and summarize
    final lines = context.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) return '';
    
    // Take first meaningful line or summarize
    final firstLine = lines.first.trim();
    return firstLine.length > 100 ? '${firstLine.substring(0, 97)}...' : firstLine;
  }

  /// Summarize memory content to essential information
  String _summarizeMemory(String content, String source) {
    if (content.length <= 50) return '$source: $content';
    
    // Extract key phrases or first sentence
    final sentences = content.split('.').where((s) => s.trim().isNotEmpty).toList();
    if (sentences.isEmpty) return '';
    
    final firstSentence = sentences.first.trim();
    final summary = firstSentence.length > 50 ? '${firstSentence.substring(0, 47)}...' : firstSentence;
    
    return '$source: $summary';
  }

  /// Get MBTI communication hint in minimal format
  String _getMBTIHint(String mbtiType) {
    final first = mbtiType.substring(0, 1);
    final third = mbtiType.substring(2, 3);
    
    final style = first == 'E' ? 'interaktif' : 'reflektif';
    final approach = third == 'T' ? 'logis' : 'empatik';
    
    return '$style, $approach';
  }

  /// Fallback minimal prompt when all else fails
  String _getMinimalPrompt() {
    return '''You are Persona, a caring AI companion.

STYLE:
- Be warm, natural, and personally engaging
- Support their personal growth journey  
- Use Indonesian when appropriate
- NEVER use emotional stage directions in parentheses

CRITICAL FORMATTING RULES:
- NEVER use numbered lists (1. 2. 3.)
- NEVER use bullet points (•, -, *)
- NEVER use "tips", "cara", "langkah", "berikut ini:"
- Write in natural paragraph format only
- Keep responses conversational and flowing
- Maximum 2 paragraphs total (320 characters max)
- Each paragraph should be naturally readable

BUBBLE SPLITTING RULES:
- For longer responses (>160 chars), split into 2 paragraphs using <span>
- Format: "First paragraph <span> Second paragraph"
- First paragraph: empathy/understanding (max 160 chars)
- Second paragraph: advice/question/technique (max 160 chars)
- Example: "Aku paham perasaanmu saat ini sangat berat dan melelahkan. <span> Bagaimana kalau kita coba teknik pernapasan sederhana untuk menenangkan pikiran?"
- For short responses (<160 chars): NO <span>, use single paragraph
- ALWAYS ensure each paragraph is complete and makes sense alone

Respond as a caring friend who genuinely understands them.''';
  }

  /// Clear cache when needed
  void clearCache() {
    _cachedPrompt = null;
    _cachedUserMessage = null;
    _lastPromptGeneration = null;
  }
}
