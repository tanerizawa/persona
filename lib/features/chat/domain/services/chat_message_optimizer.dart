// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:injectable/injectable.dart';

@injectable
class ChatMessageOptimizer {
  static const int maxCharacterPerBubble = 160;
  static const int maxTotalCharacters = 300; // Reduced to ensure both bubbles fit comfortably
  
  /// Split AI response into dynamic bubbles based on natural paragraphs
  List<String> optimizeAIResponse(String response) {
    try {
      // Clean up response first and aggressively truncate
      final cleanResponse = _cleanResponse(response);
      
      // Always truncate to prevent API responses from being too long
      final truncatedResponse = _aggressiveTruncate(cleanResponse);
      
      // FAIL-SAFE 1: If response is empty or too short, return as-is
      if (truncatedResponse.trim().isEmpty) {
        return [response.trim().isNotEmpty ? response : 'Maaf, saya tidak bisa memahami. Bisa dijelaskan lagi?'];
      }
      
      // FAIL-SAFE 2: Check if AI still sent lists/inappropriate format
      if (_hasInappropriateFormatting(truncatedResponse)) {
        // Clean it aggressively but return as single bubble to preserve context
        final fallbackClean = _cleanInappropriateFormatting(truncatedResponse);
        return [fallbackClean];
      }
      
      // Priority 1: Check for <span> separator (AI explicitly wants 2 bubbles)
      if (truncatedResponse.contains('<span>')) {
        final spanResult = _splitBySpanSeparator(truncatedResponse);
        if (spanResult.length == 2) {
          return spanResult;
        }
        // If span split failed, the single result should already be cleaned
        return spanResult;
      }
      
      // Priority 2: Split into natural paragraphs only if response is long enough
      if (truncatedResponse.length > maxCharacterPerBubble) {
        final naturalSplit = _splitIntoDynamicParagraphs(truncatedResponse);
        if (naturalSplit.length == 2) {
          return naturalSplit;
        }
        // If natural split failed but response is still too long for single bubble, force truncate
        if (naturalSplit.length == 1 && naturalSplit[0].length > maxCharacterPerBubble + 20) {
          final forceTruncated = _forceTruncateToSingleBubble(naturalSplit[0]);
          return [forceTruncated];
        }
      }
      
      // Default: Return as single bubble (ALWAYS SAFE)
      return [truncatedResponse];
      
    } catch (e) {
      // ULTIMATE FAIL-SAFE: Return original response if anything fails
      return [response.trim().isNotEmpty ? response : 'Maaf, ada kesalahan. Bisa dicoba lagi?'];
    }
  }
  
  /// Clean response from unwanted elements and remove lists/tips
  String _cleanResponse(String response) {
    String cleaned = response
        .replaceAll(RegExp(r'\([^)]*\)'), '') // Remove parenthetical emotions
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
    
    // DON'T pre-clean - let the inappropriate formatting check handle it
    // Only do very light cleaning here
    cleaned = _removeExcessiveTherapyLists(cleaned);
    
    return cleaned;
  }
  
  /// Remove only excessive therapy list patterns, keep normal mentions
  String _removeExcessiveTherapyLists(String text) {
    // Only remove if there are multiple therapy techniques listed together
    if (text.contains(RegExp(r'teknik.*meditasi.*journaling', caseSensitive: false)) ||
        text.contains(RegExp(r'\d+\.\s+(teknik|mindfulness|meditasi)', caseSensitive: false))) {
      
      final tipsPatterns = [
        r'\d+\.\s+teknik pernapasan[^.]*\.',
        r'\d+\.\s+mindfulness[^.]*\.',
        r'\d+\.\s+meditasi[^.]*\.',
        r'\d+\.\s+journaling[^.]*\.',
        r'\d+\.\s+olahraga[^.]*\.',
      ];
      
      for (final pattern in tipsPatterns) {
        text = text.replaceAll(RegExp(pattern, caseSensitive: false), '');
      }
    }
    
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  
  /// Aggressively truncate response to ensure it's within limits
  String _aggressiveTruncate(String response) {
    if (response.length <= maxTotalCharacters) {
      return response;
    }
    
    // For very long responses, prioritize fitting within total character limit
    // Try to find natural sentence boundaries first
    final sentences = response.split(RegExp(r'[.!?]\s+')).where((s) => s.trim().isNotEmpty).toList();
    String result = '';
    
    // Build response sentence by sentence until we approach the limit
    for (final sentence in sentences) {
      final potentialResult = result.isEmpty 
          ? sentence.trim() + '.'
          : result + ' ' + sentence.trim() + '.';
      
      // Leave buffer for potential second bubble (conservative)
      if (potentialResult.length <= maxTotalCharacters - 20) {
        result = potentialResult;
      } else {
        break;
      }
    }
    
    // If no sentences fit or result is too short, force truncate intelligently
    if (result.isEmpty || result.length < 30) {
      // Find last space to avoid cutting words
      final targetLength = maxTotalCharacters - 20;
      if (response.length > targetLength) {
        final lastSpace = response.lastIndexOf(' ', targetLength);
        if (lastSpace > targetLength - 50) {
          result = response.substring(0, lastSpace).trim() + '...';
        } else {
          result = response.substring(0, targetLength).trim() + '...';
        }
      } else {
        result = response;
      }
    }
    
    return result;
  }
   /// Split into dynamic paragraphs (not constrained by character limits per bubble)
  List<String> _splitIntoDynamicParagraphs(String response) {
    try {
      // If response is short, return as single bubble
      if (response.length <= maxCharacterPerBubble) {
        return [response];
      }
      
      // FAIL-SAFE: Double-check for inappropriate formatting before splitting
      if (_hasInappropriateFormatting(response)) {
        return [response]; // Keep as single bubble to preserve context
      }

      final sentences = response.split(RegExp(r'[.!?]\s+')).where((s) => s.trim().isNotEmpty).toList();
      
      if (sentences.length <= 1) {
        // Single long sentence, return as is (dynamic bubble will wrap it)
        return [response];
      }
      
      // Look for natural break points
      final splitResult = _findNaturalBreakPoint(sentences);
      if (splitResult != null && splitResult.length == 2) {
        // FAIL-SAFE: Verify both parts don't have inappropriate formatting
        final firstPart = splitResult[0];
        final secondPart = splitResult[1];
        
        if (_hasInappropriateFormatting(firstPart) || _hasInappropriateFormatting(secondPart)) {
          return [response]; // Keep as single bubble if split parts have issues
        }
        
        // Ensure both parts are meaningful
        if (firstPart.trim().length < 10 || secondPart.trim().length < 10) {
          return [response];
        }
        
        return splitResult;
      }
      
      // If no natural break, try to split roughly in the middle
      final midPoint = (sentences.length / 2).ceil();
      final firstPart = sentences.sublist(0, midPoint).join('. ').trim() + '.';
      final secondPart = sentences.sublist(midPoint).join('. ').trim();
      
      // FAIL-SAFE: Verify split parts don't have inappropriate formatting
      if (_hasInappropriateFormatting(firstPart) || _hasInappropriateFormatting(secondPart)) {
        return [response]; // Keep as single bubble if split creates issues
      }
      
      // Ensure both parts are meaningful
      if (firstPart.trim().length < 10 || secondPart.trim().length < 10) {
        return [response];
      }
      
      return [firstPart, secondPart];
      
    } catch (e) {
      // Any error: return as single bubble
      return [response];
    }
  }
  
  /// Find natural break point for paragraph splitting
  List<String>? _findNaturalBreakPoint(List<String> sentences) {
    // Strategy 1: Look for counseling technique (question) at the end
    for (int i = sentences.length - 1; i >= 1; i--) {
      final sentence = sentences[i].trim();
      if (_isQuestionOrTechnique(sentence)) {
        final responsePart = sentences.sublist(0, i).join('. ').trim() + '.';
        final techniquePart = sentences.sublist(i).join('. ').trim();
        
        // Accept any split that makes sense (remove character constraints)
        if (responsePart.length > 20 && techniquePart.length > 10) {
          return [responsePart, techniquePart];
        }
      }
    }
    
    // Strategy 2: Look for transition words/phrases
    for (int i = 1; i < sentences.length - 1; i++) {
      final sentence = sentences[i].toLowerCase();
      if (_hasTransitionWord(sentence)) {
        final firstPart = sentences.sublist(0, i).join('. ').trim() + '.';
        final secondPart = sentences.sublist(i).join('. ').trim();
        
        if (firstPart.length > 30 && secondPart.length > 20) {
          return [firstPart, secondPart];
        }
      }
    }
    
    return null;
  }
  
  /// Check for transition words that indicate natural break points
  bool _hasTransitionWord(String sentence) {
    final transitions = [
      'namun', 'tetapi', 'akan tetapi', 'namun demikian', 'selain itu',
      'di sisi lain', 'sebaliknya', 'meskipun', 'walaupun', 'bagaimanapun',
      'oleh karena itu', 'dengan demikian', 'jadi', 'sehingga',
      'however', 'but', 'nevertheless', 'on the other hand', 'therefore'
    ];
    
    return transitions.any((transition) => sentence.contains(transition));
  }
  
  /// Check if sentence contains question or counseling technique
  bool _isQuestionOrTechnique(String sentence) {
    final indicators = [
      'bagaimana', 'apa', 'kenapa', 'bisakah', 'menurutmu', 'coba',
      'how', 'what', 'why', 'can you', 'could you', 'would you'
    ];
    
    final lowerSentence = sentence.toLowerCase();
    return indicators.any((indicator) => lowerSentence.contains(indicator)) ||
           sentence.contains('?');
  }
  
  /// FAIL-SAFE: Check if AI response still contains inappropriate formatting
  bool _hasInappropriateFormatting(String response) {
    final lowerResponse = response.toLowerCase();
    
    // Check for numbered lists - more specific patterns
    if (RegExp(r'\d+\.\s+[a-zA-Z]').hasMatch(response)) {
      return true;
    }
    
    // Check for bullet points - more specific patterns
    if (RegExp(r'[•\-\*]\s+[a-zA-Z]').hasMatch(response)) {
      return true;
    }
    
    // Check for explicit list indicators (including without colon)
    final listIndicators = [
      'berikut ini:', 'sebagai berikut:', 'tips:', 'cara:', 'langkah:',
      'berikut ini ', 'tips untuk', 'cara untuk', 'langkah ',
      'following:', 'tips for', 'steps:', 'ways to', 'methods:'
    ];
    
    for (final indicator in listIndicators) {
      if (lowerResponse.contains(indicator)) {
        return true;
      }
    }
    
    // Check for multiple therapy technique mentions (likely a list)
    final therapyPatterns = [
      'mindfulness', 'meditasi', 'journaling', 'pernapasan', 'grounding'
    ];
    int therapyCount = 0;
    for (final pattern in therapyPatterns) {
      if (lowerResponse.contains(pattern)) {
        therapyCount++;
      }
    }
    
    // If 3+ therapy techniques mentioned, likely a list
    if (therapyCount >= 3) {
      return true;
    }
    
    return false;
  }
  
  /// Clean inappropriate formatting (lists, bullets, etc.)
  String _cleanInappropriateFormatting(String text) {
    String cleaned = text
        .replaceAll('<span>', '') // ALWAYS remove any remaining spans
        .replaceAll(RegExp(r'\d+\.\s*'), '') // Remove numbered list items
        .replaceAll(RegExp(r'[•\-\*]\s*'), '') // Remove bullet points
        .replaceAll(RegExp(r'berikut ini.*?:', caseSensitive: false), '') // Remove list introductions
        .replaceAll(RegExp(r'tips.*?:', caseSensitive: false), '') // Remove tips introductions
        .replaceAll(RegExp(r'cara.*?:', caseSensitive: false), '') // Remove cara introductions
        .replaceAll(RegExp(r'langkah.*?:', caseSensitive: false), '') // Remove langkah introductions
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
    
    // If cleaning results in empty or too short text, provide fallback
    if (cleaned.isEmpty || cleaned.length < 10) {
      return 'Aku memahami maksudmu. Mari kita bicara lebih lanjut tentang hal ini.';
    }
    
    return cleaned;
  }

  /// Split response by <span> separator (AI explicitly requested 2 bubbles)
  List<String> _splitBySpanSeparator(String response) {
    try {
      final parts = response.split('<span>');
      
      if (parts.length < 2) {
        // No valid split, return as single bubble after cleaning
        return [_cleanInappropriateFormatting(response)];
      }
      
      final firstPart = parts[0].trim();
      final remainingParts = parts.sublist(1);
      final secondPart = remainingParts.join(' ').replaceAll('<span>', '').trim(); // Clean remaining spans too
      
      // Validate both parts are meaningful (not empty and have minimum length)
      if (firstPart.isEmpty || secondPart.isEmpty || firstPart.length < 10 || secondPart.length < 10) {
        return [_cleanInappropriateFormatting(response)];
      }
      
      // FAIL-SAFE: Check each part for inappropriate formatting
      if (_hasInappropriateFormatting(firstPart) || _hasInappropriateFormatting(secondPart)) {
        return [_cleanInappropriateFormatting(response)];
      }
      
      // VALIDATION: Ensure both parts are not too long (respect bubble limits)
      String validFirstPart = firstPart;
      String validSecondPart = secondPart;
      
      if (firstPart.length > maxCharacterPerBubble + 20) {
        // Find last sentence boundary within limit
        final lastPeriod = firstPart.lastIndexOf('.', maxCharacterPerBubble);
        if (lastPeriod > 50) {
          validFirstPart = firstPart.substring(0, lastPeriod + 1).trim();
        } else {
          validFirstPart = '${firstPart.substring(0, maxCharacterPerBubble - 3)}...';
        }
      }
      
      if (secondPart.length > maxCharacterPerBubble + 20) {
        // Find last sentence boundary within limit
        final lastPeriod = secondPart.lastIndexOf('.', maxCharacterPerBubble);
        if (lastPeriod > 20) {
          validSecondPart = secondPart.substring(0, lastPeriod + 1).trim();
        } else {
          validSecondPart = '${secondPart.substring(0, maxCharacterPerBubble - 3)}...';
        }
      }
      
      // Both parts are valid, return as 2 bubbles
      return [validFirstPart, validSecondPart];
      
    } catch (e) {
      // Any error: return as single bubble
      return [_cleanInappropriateFormatting(response)];
    }
  }
  
  /// Force truncate to single bubble limit for responses that can't be split
  String _forceTruncateToSingleBubble(String response) {
    if (response.length <= maxCharacterPerBubble + 20) {
      return response;
    }
    
    // Try to find last sentence boundary within bubble limit
    final targetLength = maxCharacterPerBubble + 10; // Small buffer
    final lastPeriod = response.lastIndexOf('.', targetLength);
    
    if (lastPeriod > maxCharacterPerBubble - 30) {
      // Good sentence boundary found
      return response.substring(0, lastPeriod + 1).trim();
    }
    
    // No good sentence boundary, find last space
    final lastSpace = response.lastIndexOf(' ', targetLength);
    if (lastSpace > maxCharacterPerBubble - 20) {
      return response.substring(0, lastSpace).trim() + '...';
    }
    
    // Last resort: hard cut
    return response.substring(0, targetLength).trim() + '...';
  }

}
