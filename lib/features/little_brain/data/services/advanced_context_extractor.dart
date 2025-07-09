import 'dart:math' as math;

/// Advanced context extraction dengan pattern recognition dan machine learning approach
class AdvancedContextExtractor {
  static const Map<String, ContextConfig> contextConfigs = {
    'work': ContextConfig(
      patterns: [
        // Indonesian work-related terms
        'kerja', 'kantor', 'meeting', 'rapat', 'project', 'proyek', 'deadline',
        'boss', 'atasan', 'rekan kerja', 'colleague', 'client', 'klien',
        'presentasi', 'laporan', 'tugas', 'overtime', 'lembur', 'gaji',
        'promosi', 'karir', 'interview', 'wawancara', 'resign', 'mundur',
        // English work terms
        'office', 'work', 'job', 'career', 'business', 'professional',
        'conference', 'workshop', 'training', 'performance', 'review',
        'salary', 'promotion', 'resignation', 'teamwork', 'leadership'
      ],
      timePatterns: ['pagi', 'siang', 'sore', 'morning', 'afternoon', 'evening'],
      locationPatterns: ['kantor', 'office', 'ruang meeting', 'conference room'],
      priority: 0.8,
      emotionalImpact: 0.6,
    ),
    
    'family': ContextConfig(
      patterns: [
        // Indonesian family terms
        'keluarga', 'orang tua', 'ayah', 'ibu', 'bapak', 'mama', 'papa',
        'anak', 'adik', 'kakak', 'suami', 'istri', 'mertua', 'nenek',
        'kakek', 'paman', 'tante', 'sepupu', 'saudara', 'keponakan',
        // English family terms
        'family', 'parents', 'father', 'mother', 'dad', 'mom', 'son',
        'daughter', 'brother', 'sister', 'husband', 'wife', 'grandparents',
        'uncle', 'aunt', 'cousin', 'nephew', 'niece', 'in-laws'
      ],
      timePatterns: ['weekend', 'holiday', 'libur', 'family time'],
      locationPatterns: ['rumah', 'home', 'dapur', 'kitchen', 'ruang keluarga'],
      priority: 0.9,
      emotionalImpact: 0.8,
    ),
    
    'friends': ContextConfig(
      patterns: [
        // Indonesian friendship terms
        'teman', 'sahabat', 'bestie', 'bro', 'sis', 'squad', 'geng',
        'hangout', 'nongkrong', 'kumpul', 'reunion', 'arisan', 'chat',
        'gosip', 'cerita', 'curhat', 'sharing', 'support', 'bantuan',
        // English friendship terms
        'friend', 'buddy', 'pal', 'mate', 'colleague', 'roommate',
        'social', 'party', 'gathering', 'catch up', 'support', 'advice'
      ],
      timePatterns: ['weekend', 'malam', 'night', 'evening', 'friday'],
      locationPatterns: ['cafe', 'restaurant', 'mall', 'park', 'taman'],
      priority: 0.7,
      emotionalImpact: 0.7,
    ),
    
    'hobby': ContextConfig(
      patterns: [
        // Indonesian hobby terms
        'hobi', 'musik', 'menyanyi', 'guitar', 'piano', 'drum', 'band',
        'olahraga', 'gym', 'fitness', 'yoga', 'jogging', 'sepeda',
        'membaca', 'buku', 'novel', 'komik', 'manga', 'anime',
        'game', 'gaming', 'main game', 'ps4', 'xbox', 'mobile game',
        'melukis', 'menggambar', 'fotografi', 'traveling', 'jalan-jalan',
        'masak', 'memasak', 'cooking', 'baking', 'resep', 'kuliner',
        // English hobby terms
        'music', 'singing', 'instrument', 'sports', 'exercise', 'reading',
        'gaming', 'painting', 'drawing', 'photography', 'travel', 'cooking'
      ],
      timePatterns: ['weekend', 'free time', 'waktu luang', 'sore', 'evening'],
      locationPatterns: ['gym', 'studio', 'park', 'home', 'outdoor'],
      priority: 0.6,
      emotionalImpact: 0.8,
    ),
    
    'health': ContextConfig(
      patterns: [
        // Indonesian health terms
        'kesehatan', 'sakit', 'dokter', 'rumah sakit', 'obat', 'medicine',
        'demam', 'flu', 'batuk', 'pilek', 'pusing', 'mual', 'lelah',
        'diet', 'makan sehat', 'exercise', 'olahraga', 'vitamin',
        'check up', 'periksa', 'konsultasi', 'therapy', 'terapi',
        // English health terms
        'health', 'sick', 'illness', 'doctor', 'hospital', 'medicine',
        'fever', 'headache', 'tired', 'fatigue', 'stress', 'anxiety',
        'diet', 'nutrition', 'wellness', 'fitness', 'medical', 'treatment'
      ],
      timePatterns: ['pagi', 'morning', 'malam', 'night'],
      locationPatterns: ['rumah sakit', 'hospital', 'clinic', 'klinik', 'gym'],
      priority: 0.9,
      emotionalImpact: 0.7,
    ),
    
    'education': ContextConfig(
      patterns: [
        // Indonesian education terms
        'belajar', 'sekolah', 'kuliah', 'universitas', 'kampus', 'kelas',
        'ujian', 'exam', 'test', 'tugas', 'assignment', 'skripsi', 'thesis',
        'dosen', 'guru', 'professor', 'student', 'mahasiswa', 'siswa',
        'kursus', 'course', 'training', 'workshop', 'seminar', 'conference',
        'nilai', 'grade', 'ipk', 'gpa', 'lulus', 'graduate', 'wisuda',
        // English education terms
        'study', 'school', 'college', 'university', 'class', 'lecture',
        'homework', 'research', 'academic', 'scholarship', 'diploma'
      ],
      timePatterns: ['pagi', 'siang', 'morning', 'afternoon', 'weekday'],
      locationPatterns: ['sekolah', 'kampus', 'kelas', 'library', 'lab'],
      priority: 0.7,
      emotionalImpact: 0.6,
    ),
    
    'relationship': ContextConfig(
      patterns: [
        // Indonesian relationship terms
        'pacar', 'boyfriend', 'girlfriend', 'cinta', 'sayang', 'hubungan',
        'pacaran', 'jadian', 'putus', 'break up', 'pdkt', 'crush',
        'valentine', 'anniversary', 'romantic', 'romantis', 'date',
        'kencan', 'tunangan', 'nikah', 'menikah', 'wedding', 'married',
        // English relationship terms
        'love', 'relationship', 'dating', 'romance', 'partner', 'couple',
        'engagement', 'marriage', 'divorce', 'breakup', 'commitment'
      ],
      timePatterns: ['weekend', 'evening', 'valentine', 'anniversary'],
      locationPatterns: ['restaurant', 'park', 'cinema', 'cafe', 'beach'],
      priority: 0.8,
      emotionalImpact: 0.9,
    ),
    
    'finance': ContextConfig(
      patterns: [
        // Indonesian finance terms
        'uang', 'money', 'duit', 'finansial', 'keuangan', 'gaji', 'salary',
        'tabungan', 'saving', 'investasi', 'investment', 'saham', 'stock',
        'bank', 'atm', 'kredit', 'hutang', 'debt', 'cicilan', 'pinjaman',
        'belanja', 'shopping', 'beli', 'buy', 'jual', 'sell', 'harga',
        'budget', 'anggaran', 'hemat', 'boros', 'expensive', 'cheap',
        // English finance terms
        'finance', 'budget', 'expense', 'income', 'profit', 'loss',
        'loan', 'mortgage', 'insurance', 'tax', 'payment', 'transaction'
      ],
      timePatterns: ['end of month', 'payday', 'akhir bulan'],
      locationPatterns: ['bank', 'atm', 'mall', 'toko', 'store'],
      priority: 0.7,
      emotionalImpact: 0.6,
    ),
    
    'technology': ContextConfig(
      patterns: [
        // Indonesian technology terms
        'teknologi', 'komputer', 'laptop', 'handphone', 'hp', 'smartphone',
        'internet', 'wifi', 'software', 'aplikasi', 'app', 'website',
        'coding', 'programming', 'developer', 'programmer', 'bug', 'error',
        'update', 'upgrade', 'download', 'install', 'backup', 'virus',
        // English technology terms
        'technology', 'computer', 'software', 'hardware', 'digital',
        'AI', 'artificial intelligence', 'machine learning', 'data',
        'cloud', 'cybersecurity', 'blockchain', 'automation'
      ],
      timePatterns: ['any time', 'work hours', 'late night'],
      locationPatterns: ['office', 'home', 'co-working space'],
      priority: 0.6,
      emotionalImpact: 0.5,
    ),
  };

  /// Extract contexts from text with advanced pattern matching
  static ContextResult extractContexts(String text, {DateTime? timestamp}) {
    final detectedContexts = <DetectedContext>[];
    final lowerText = text.toLowerCase();
    
    for (final entry in contextConfigs.entries) {
      final contextName = entry.key;
      final config = entry.value;
      
      double confidence = 0.0;
      int matchCount = 0;
      List<String> matchedPatterns = [];
      
      // Check for pattern matches
      for (final pattern in config.patterns) {
        if (lowerText.contains(pattern.toLowerCase())) {
          matchCount++;
          confidence += _calculatePatternWeight(pattern, text);
          matchedPatterns.add(pattern);
        }
      }
      
      if (matchCount > 0) {
        // Normalize confidence
        confidence = (confidence / config.patterns.length).clamp(0.0, 1.0);
        
        // Apply time-based boost
        confidence = _applyTimeBoost(confidence, config, timestamp);
        
        // Apply co-occurrence boost
        confidence = _applyCooccurrenceBoost(confidence, contextName, detectedContexts);
        
        // Apply priority modifier
        confidence = confidence * config.priority;
        
        if (confidence > 0.1) { // Minimum threshold
          detectedContexts.add(DetectedContext(
            context: contextName,
            confidence: confidence,
            matchCount: matchCount,
            matchedPatterns: matchedPatterns,
            emotionalImpact: config.emotionalImpact,
          ));
        }
      }
    }
    
    // Sort by confidence
    detectedContexts.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // Generate context tags
    final contextTags = _generateContextTags(detectedContexts);
    
    return ContextResult(
      contexts: detectedContexts.take(5).toList(), // Top 5 contexts
      primaryContext: detectedContexts.isNotEmpty ? detectedContexts.first.context : 'general',
      contextTags: contextTags,
      overallConfidence: detectedContexts.isNotEmpty ? detectedContexts.first.confidence : 0.0,
      contextComplexity: detectedContexts.length,
    );
  }

  /// Calculate weight of pattern based on specificity and frequency
  static double _calculatePatternWeight(String pattern, String text) {
    double weight = 0.3; // Base weight
    
    // Longer patterns get higher weight (more specific)
    weight += math.min(0.4, pattern.length / 20.0);
    
    // Multi-word patterns get bonus
    if (pattern.contains(' ')) {
      weight += 0.2;
    }
    
    // Check for exact word match vs substring match
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    if (words.contains(pattern.toLowerCase())) {
      weight += 0.3; // Exact word match bonus
    }
    
    // Check for repeated mentions
    final count = RegExp(pattern.toLowerCase()).allMatches(text.toLowerCase()).length;
    if (count > 1) {
      weight += math.min(0.2, count * 0.05);
    }
    
    return weight.clamp(0.1, 1.0);
  }

  /// Apply time-based contextual boost
  static double _applyTimeBoost(double confidence, ContextConfig config, DateTime? timestamp) {
    if (timestamp == null) return confidence;
    
    final hour = timestamp.hour;
    final dayOfWeek = timestamp.weekday;
    
    // Work context gets boost during work hours
    if (config == contextConfigs['work']) {
      if (hour >= 9 && hour <= 17 && dayOfWeek <= 5) { // 9 AM - 5 PM, weekdays
        confidence = math.min(1.0, confidence * 1.3);
      }
    }
    
    // Hobby context gets boost during weekends and evenings
    if (config == contextConfigs['hobby']) {
      if (dayOfWeek >= 6 || hour >= 18 || hour <= 8) { // Weekends or evenings
        confidence = math.min(1.0, confidence * 1.2);
      }
    }
    
    // Family context gets boost during weekends
    if (config == contextConfigs['family']) {
      if (dayOfWeek >= 6) { // Weekends
        confidence = math.min(1.0, confidence * 1.2);
      }
    }
    
    return confidence;
  }

  /// Apply co-occurrence boost when related contexts appear together
  static double _applyCooccurrenceBoost(double confidence, String contextName, List<DetectedContext> existingContexts) {
    final relatedContexts = {
      'work': ['technology', 'finance'],
      'hobby': ['friends', 'family'],
      'health': ['family', 'education'],
      'relationship': ['friends', 'family'],
      'education': ['technology', 'friends'],
    };
    
    final related = relatedContexts[contextName] ?? [];
    
    for (final existing in existingContexts) {
      if (related.contains(existing.context)) {
        confidence = math.min(1.0, confidence * 1.15);
        break;
      }
    }
    
    return confidence;
  }

  /// Generate context tags for memory storage
  static List<String> _generateContextTags(List<DetectedContext> contexts) {
    final tags = <String>[];
    
    for (final context in contexts) {
      // Add primary context tag
      tags.add('context:${context.context}');
      
      // Add specific pattern tags for high confidence contexts
      if (context.confidence > 0.7) {
        for (final pattern in context.matchedPatterns.take(2)) {
          tags.add('pattern:$pattern');
        }
      }
      
      // Add emotional impact tags
      if (context.emotionalImpact > 0.8) {
        tags.add('high_emotional_impact');
      }
    }
    
    return tags.take(10).toList(); // Limit tags
  }

  /// Extract temporal contexts (morning, evening, weekend, etc.)
  static List<String> extractTemporalContexts(String text, DateTime? timestamp) {
    final temporalContexts = <String>[];
    final lowerText = text.toLowerCase();
    
    // Time of day patterns
    final timePatterns = {
      'morning': ['pagi', 'morning', 'dawn', 'subuh', 'sunrise'],
      'afternoon': ['siang', 'afternoon', 'noon', 'lunch time'],
      'evening': ['sore', 'evening', 'sunset', 'maghrib'],
      'night': ['malam', 'night', 'midnight', 'late night'],
    };
    
    for (final entry in timePatterns.entries) {
      for (final pattern in entry.value) {
        if (lowerText.contains(pattern)) {
          temporalContexts.add('time:${entry.key}');
          break;
        }
      }
    }
    
    // Day patterns
    final dayPatterns = {
      'weekend': ['weekend', 'sabtu', 'minggu', 'saturday', 'sunday'],
      'weekday': ['weekday', 'senin', 'selasa', 'rabu', 'kamis', 'jumat'],
      'holiday': ['holiday', 'libur', 'vacation', 'cuti'],
    };
    
    for (final entry in dayPatterns.entries) {
      for (final pattern in entry.value) {
        if (lowerText.contains(pattern)) {
          temporalContexts.add('day:${entry.key}');
          break;
        }
      }
    }
    
    // If timestamp is available, add automatic temporal context
    if (timestamp != null) {
      final hour = timestamp.hour;
      if (hour >= 6 && hour < 12) {
        temporalContexts.add('time:morning');
      } else if (hour >= 12 && hour < 17) {
        temporalContexts.add('time:afternoon');
      } else if (hour >= 17 && hour < 21) {
        temporalContexts.add('time:evening');
      } else {
        temporalContexts.add('time:night');
      }
      
      final dayOfWeek = timestamp.weekday;
      if (dayOfWeek >= 6) {
        temporalContexts.add('day:weekend');
      } else {
        temporalContexts.add('day:weekday');
      }
    }
    
    return temporalContexts.toSet().toList(); // Remove duplicates
  }

  /// Extract location contexts from text
  static List<String> extractLocationContexts(String text) {
    final locationContexts = <String>[];
    final lowerText = text.toLowerCase();
    
    final locationPatterns = {
      'home': ['rumah', 'home', 'house', 'kamar', 'bedroom', 'dapur', 'kitchen'],
      'office': ['kantor', 'office', 'workplace', 'meeting room', 'ruang kerja'],
      'school': ['sekolah', 'school', 'kampus', 'university', 'college', 'kelas'],
      'outdoor': ['outdoor', 'park', 'taman', 'beach', 'pantai', 'mountain', 'gunung'],
      'social': ['cafe', 'restaurant', 'mall', 'cinema', 'bioskop', 'club'],
      'transport': ['mobil', 'car', 'bus', 'train', 'kereta', 'pesawat', 'plane'],
    };
    
    for (final entry in locationPatterns.entries) {
      for (final pattern in entry.value) {
        if (lowerText.contains(pattern)) {
          locationContexts.add('location:${entry.key}');
          break;
        }
      }
    }
    
    return locationContexts;
  }

  /// Generate comprehensive context summary
  static String generateContextSummary(ContextResult result) {
    if (result.contexts.isEmpty) {
      return 'General context with no specific domain identified.';
    }
    
    final primary = result.contexts.first;
    String summary = 'Primary context: ${primary.context} (${(primary.confidence * 100).toInt()}% confidence)';
    
    if (result.contexts.length > 1) {
      final secondary = result.contexts[1];
      summary += ', with ${secondary.context} elements';
    }
    
    if (result.contextComplexity > 3) {
      summary += '. Multi-domain context detected';
    }
    
    final highImpactContexts = result.contexts.where((c) => c.emotionalImpact > 0.8).toList();
    if (highImpactContexts.isNotEmpty) {
      summary += '. High emotional significance identified';
    }
    
    return summary;
  }
}

/// Configuration for each context type
class ContextConfig {
  final List<String> patterns;
  final List<String> timePatterns;
  final List<String> locationPatterns;
  final double priority;
  final double emotionalImpact;
  
  const ContextConfig({
    required this.patterns,
    required this.timePatterns,
    required this.locationPatterns,
    required this.priority,
    required this.emotionalImpact,
  });
}

/// Result of context extraction
class ContextResult {
  final List<DetectedContext> contexts;
  final String primaryContext;
  final List<String> contextTags;
  final double overallConfidence;
  final int contextComplexity;
  
  const ContextResult({
    required this.contexts,
    required this.primaryContext,
    required this.contextTags,
    required this.overallConfidence,
    required this.contextComplexity,
  });
  
  bool get hasStrongContext => overallConfidence > 0.7;
  bool get hasMultipleContexts => contextComplexity > 2;
  bool get isGeneral => contexts.isEmpty || overallConfidence < 0.2;
}

/// Individual detected context with metadata
class DetectedContext {
  final String context;
  final double confidence;
  final int matchCount;
  final List<String> matchedPatterns;
  final double emotionalImpact;
  
  const DetectedContext({
    required this.context,
    required this.confidence,
    required this.matchCount,
    required this.matchedPatterns,
    required this.emotionalImpact,
  });
}
