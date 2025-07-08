import 'package:equatable/equatable.dart';

/// MBTI personality type result
class MBTIResult extends Equatable {
  final String id;
  final DateTime timestamp;
  final String personalityType; // e.g., "INTJ", "ENFP"
  final Map<String, int> scores; // E/I, S/N, T/F, J/P scores
  final String description;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> careers;
  final Map<String, dynamic>? metadata;

  const MBTIResult({
    required this.id,
    required this.timestamp,
    required this.personalityType,
    required this.scores,
    required this.description,
    required this.strengths,
    required this.weaknesses,
    required this.careers,
    this.metadata,
  });

  /// Convert to memory format for Little Brain storage
  Map<String, dynamic> toMemoryContent() {
    return {
      'type': 'mbti_result',
      'personality_type': personalityType,
      'scores': scores,
      'description': description,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'careers': careers,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        personalityType,
        scores,
        description,
        strengths,
        weaknesses,
        careers,
        metadata,
      ];
}

/// BDI (Beck Depression Inventory) result
class BDIResult extends Equatable {
  final String id;
  final DateTime timestamp;
  final int totalScore;
  final DepressionLevel level;
  final String description;
  final List<String> recommendations;
  final bool needsCrisisIntervention;
  final Map<String, int>? categoryScores; // Different aspects of depression
  final Map<String, dynamic>? metadata;

  const BDIResult({
    required this.id,
    required this.timestamp,
    required this.totalScore,
    required this.level,
    required this.description,
    required this.recommendations,
    required this.needsCrisisIntervention,
    this.categoryScores,
    this.metadata,
  });

  /// Convert to memory format for Little Brain storage
  Map<String, dynamic> toMemoryContent() {
    return {
      'type': 'bdi_result',
      'total_score': totalScore,
      'level': level.name,
      'description': description,
      'recommendations': recommendations,
      'needs_crisis_intervention': needsCrisisIntervention,
      'category_scores': categoryScores,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        totalScore,
        level,
        description,
        recommendations,
        needsCrisisIntervention,
        categoryScores,
        metadata,
      ];
}

/// Depression level categories
enum DepressionLevel {
  minimal,
  mild,
  moderate,
  severe;

  String get description {
    switch (this) {
      case DepressionLevel.minimal:
        return 'Minimal Depression';
      case DepressionLevel.mild:
        return 'Mild Depression';
      case DepressionLevel.moderate:
        return 'Moderate Depression';
      case DepressionLevel.severe:
        return 'Severe Depression';
    }
  }

  String get indonesianDescription {
    switch (this) {
      case DepressionLevel.minimal:
        return 'Depresi Minimal';
      case DepressionLevel.mild:
        return 'Depresi Ringan';
      case DepressionLevel.moderate:
        return 'Depresi Sedang';
      case DepressionLevel.severe:
        return 'Depresi Berat';
    }
  }
}

/// MBTI question for the test
class MBTIQuestion extends Equatable {
  final int id;
  final String question;
  final String optionA;
  final String optionB;
  final MBTIDimension dimension;

  const MBTIQuestion({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.dimension,
  });

  @override
  List<Object?> get props => [id, question, optionA, optionB, dimension];
}

/// BDI question for the test
class BDIQuestion extends Equatable {
  final int id;
  final String question;
  final List<String> options;
  final List<int> scores;

  const BDIQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.scores,
  });

  @override
  List<Object?> get props => [id, question, options, scores];
}

/// MBTI dimensions
enum MBTIDimension {
  extraversion, // E/I
  sensing, // S/N
  thinking, // T/F
  judging; // J/P

  String get code {
    switch (this) {
      case MBTIDimension.extraversion:
        return 'E/I';
      case MBTIDimension.sensing:
        return 'S/N';
      case MBTIDimension.thinking:
        return 'T/F';
      case MBTIDimension.judging:
        return 'J/P';
    }
  }
}

/// Psychology analytics for insights
class PsychologyAnalytics extends Equatable {
  final int totalMBTITests;
  final int totalBDITests;
  final MBTIResult? latestMBTI;
  final BDIResult? latestBDI;
  final List<BDIResult> bdiHistory;
  final Map<String, int> personalityTypeHistory;
  final double averageBDIScore;
  final List<String> personalityInsights;

  const PsychologyAnalytics({
    required this.totalMBTITests,
    required this.totalBDITests,
    this.latestMBTI,
    this.latestBDI,
    required this.bdiHistory,
    required this.personalityTypeHistory,
    required this.averageBDIScore,
    required this.personalityInsights,
  });

  @override
  List<Object?> get props => [
        totalMBTITests,
        totalBDITests,
        latestMBTI,
        latestBDI,
        bdiHistory,
        personalityTypeHistory,
        averageBDIScore,
        personalityInsights,
      ];
}
