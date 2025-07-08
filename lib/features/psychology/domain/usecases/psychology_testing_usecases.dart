import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../little_brain/domain/repositories/little_brain_repository.dart';
import '../../../little_brain/domain/entities/memory_entities.dart';
import '../entities/psychology_entities.dart';

@injectable
class PsychologyTestingUseCases {
  final LittleBrainRepository _littleBrainRepository;
  final Uuid _uuid = const Uuid();

  PsychologyTestingUseCases(this._littleBrainRepository);

  /// Get MBTI questions for the test
  List<MBTIQuestion> getMBTIQuestions() {
    return [
      // Extraversion vs Introversion
      const MBTIQuestion(
        id: 1,
        question: 'Ketika menghadapi masalah, saya lebih suka:',
        optionA: 'Mendiskusikannya dengan orang lain untuk mendapat perspektif',
        optionB: 'Memikirkannya sendiri terlebih dahulu sebelum berbagi',
        dimension: MBTIDimension.extraversion,
      ),
      const MBTIQuestion(
        id: 2,
        question: 'Di pesta atau acara sosial, saya biasanya:',
        optionA: 'Aktif berbicara dengan banyak orang',
        optionB: 'Lebih suka berbicara mendalam dengan beberapa orang',
        dimension: MBTIDimension.extraversion,
      ),
      const MBTIQuestion(
        id: 3,
        question: 'Setelah hari yang panjang, saya merasa berenergi dengan:',
        optionA: 'Bertemu teman atau keluarga',
        optionB: 'Menghabiskan waktu sendiri',
        dimension: MBTIDimension.extraversion,
      ),

      // Sensing vs Intuition
      const MBTIQuestion(
        id: 4,
        question: 'Saya lebih tertarik pada:',
        optionA: 'Fakta dan detail yang konkret',
        optionB: 'Pola dan kemungkinan yang abstrak',
        dimension: MBTIDimension.sensing,
      ),
      const MBTIQuestion(
        id: 5,
        question: 'Ketika belajar sesuatu yang baru, saya lebih suka:',
        optionA: 'Contoh praktis dan pengalaman langsung',
        optionB: 'Teori dan konsep umum',
        dimension: MBTIDimension.sensing,
      ),
      const MBTIQuestion(
        id: 6,
        question: 'Saya lebih percaya pada:',
        optionA: 'Pengalaman dan hal yang telah terbukti',
        optionB: 'Intuisi dan kemungkinan masa depan',
        dimension: MBTIDimension.sensing,
      ),

      // Thinking vs Feeling
      const MBTIQuestion(
        id: 7,
        question: 'Ketika membuat keputusan penting, saya lebih mengandalkan:',
        optionA: 'Logika dan analisis objektif',
        optionB: 'Perasaan dan dampak pada orang lain',
        dimension: MBTIDimension.thinking,
      ),
      const MBTIQuestion(
        id: 8,
        question: 'Dalam konflik, saya lebih cenderung:',
        optionA: 'Fokus pada fakta dan mencari solusi yang adil',
        optionB: 'Mempertimbangkan perasaan semua pihak',
        dimension: MBTIDimension.thinking,
      ),
      const MBTIQuestion(
        id: 9,
        question: 'Saya lebih menghargai:',
        optionA: 'Kebenaran dan keadilan',
        optionB: 'Harmoni dan empati',
        dimension: MBTIDimension.thinking,
      ),

      // Judging vs Perceiving
      const MBTIQuestion(
        id: 10,
        question: 'Saya lebih suka:',
        optionA: 'Merencanakan dan mengatur jadwal',
        optionB: 'Tetap fleksibel dan spontan',
        dimension: MBTIDimension.judging,
      ),
      const MBTIQuestion(
        id: 11,
        question: 'Ketika mengerjakan proyek, saya:',
        optionA: 'Menyelesaikannya jauh sebelum deadline',
        optionB: 'Bekerja dengan baik di bawah tekanan waktu',
        dimension: MBTIDimension.judging,
      ),
      const MBTIQuestion(
        id: 12,
        question: 'Saya merasa lebih nyaman dengan:',
        optionA: 'Rencana yang jelas dan terstruktur',
        optionB: 'Pilihan terbuka dan adaptasi sesuai situasi',
        dimension: MBTIDimension.judging,
      ),
    ];
  }

  /// Calculate MBTI result from answers
  Future<MBTIResult> calculateMBTIResult(Map<int, bool> answers) async {
    final scores = <String, int>{
      'E': 0, 'I': 0,
      'S': 0, 'N': 0,
      'T': 0, 'F': 0,
      'J': 0, 'P': 0,
    };

    final questions = getMBTIQuestions();
    
    for (final question in questions) {
      final answer = answers[question.id];
      if (answer == null) continue;

      switch (question.dimension) {
        case MBTIDimension.extraversion:
          if (answer) {
            scores['E'] = (scores['E'] ?? 0) + 1;
          } else {
            scores['I'] = (scores['I'] ?? 0) + 1;
          }
          break;
        case MBTIDimension.sensing:
          if (answer) {
            scores['S'] = (scores['S'] ?? 0) + 1;
          } else {
            scores['N'] = (scores['N'] ?? 0) + 1;
          }
          break;
        case MBTIDimension.thinking:
          if (answer) {
            scores['T'] = (scores['T'] ?? 0) + 1;
          } else {
            scores['F'] = (scores['F'] ?? 0) + 1;
          }
          break;
        case MBTIDimension.judging:
          if (answer) {
            scores['J'] = (scores['J'] ?? 0) + 1;
          } else {
            scores['P'] = (scores['P'] ?? 0) + 1;
          }
          break;
      }
    }

    // Determine personality type
    final type = [
      (scores['E']! > scores['I']!) ? 'E' : 'I',
      (scores['S']! > scores['N']!) ? 'S' : 'N',
      (scores['T']! > scores['F']!) ? 'T' : 'F',
      (scores['J']! > scores['P']!) ? 'J' : 'P',
    ].join();

    final result = MBTIResult(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      personalityType: type,
      scores: scores,
      description: _getMBTIDescription(type),
      strengths: _getMBTIStrengths(type),
      weaknesses: _getMBTIWeaknesses(type),
      careers: _getMBTICareers(type),
    );

    // Store in Little Brain
    await _storeMBTIResult(result);

    return result;
  }

  /// Get BDI questions for the test
  List<BDIQuestion> getBDIQuestions() {
    return [
      const BDIQuestion(
        id: 1,
        question: 'Bagaimana perasaan Anda secara umum?',
        options: [
          'Saya tidak merasa sedih',
          'Saya merasa sedih sesekali',
          'Saya merasa sedih sebagian besar waktu',
          'Saya merasa sangat sedih atau tidak bahagia',
        ],
        scores: [0, 1, 2, 3],
      ),
      const BDIQuestion(
        id: 2,
        question: 'Bagaimana pandangan Anda tentang masa depan?',
        options: [
          'Saya tidak merasa pesimis tentang masa depan',
          'Saya merasa agak pesimis tentang masa depan',
          'Saya merasa tidak ada yang ditunggu-tunggu',
          'Saya merasa masa depan tidak akan membaik',
        ],
        scores: [0, 1, 2, 3],
      ),
      const BDIQuestion(
        id: 3,
        question: 'Bagaimana perasaan Anda tentang pencapaian hidup?',
        options: [
          'Saya tidak merasa gagal',
          'Saya merasa telah gagal lebih dari rata-rata',
          'Saya merasa telah banyak gagal',
          'Saya merasa benar-benar gagal',
        ],
        scores: [0, 1, 2, 3],
      ),
      const BDIQuestion(
        id: 4,
        question: 'Seberapa puas Anda dengan kehidupan?',
        options: [
          'Saya mendapat kepuasan dari hidup seperti dulu',
          'Saya tidak menikmati hidup seperti dulu',
          'Saya tidak mendapat kepuasan dari apapun',
          'Saya tidak puas dengan segalanya',
        ],
        scores: [0, 1, 2, 3],
      ),
      const BDIQuestion(
        id: 5,
        question: 'Bagaimana perasaan Anda tentang diri sendiri?',
        options: [
          'Saya tidak merasa bersalah',
          'Saya merasa bersalah sesekali',
          'Saya merasa bersalah sebagian besar waktu',
          'Saya merasa bersalah sepanjang waktu',
        ],
        scores: [0, 1, 2, 3],
      ),
    ];
  }

  /// Calculate BDI result from answers
  Future<BDIResult> calculateBDIResult(Map<int, int> answers) async {
    int totalScore = 0;
    final questions = getBDIQuestions();

    for (final question in questions) {
      final answerIndex = answers[question.id];
      if (answerIndex != null && answerIndex < question.scores.length) {
        totalScore += question.scores[answerIndex];
      }
    }

    final level = _getBDILevel(totalScore);
    final needsCrisis = totalScore >= 29; // Severe depression threshold

    final result = BDIResult(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      totalScore: totalScore,
      level: level,
      description: _getBDIDescription(level, totalScore),
      recommendations: _getBDIRecommendations(level),
      needsCrisisIntervention: needsCrisis,
    );

    // Store in Little Brain
    await _storeBDIResult(result);

    return result;
  }

  /// Get psychology analytics from stored data
  Future<PsychologyAnalytics> getPsychologyAnalytics() async {
    final memories = await _littleBrainRepository.getMemoriesByType('mbti_result');
    final bdiMemories = await _littleBrainRepository.getMemoriesByType('bdi_result');

    final mbtiResults = memories.map((m) => _memoryToMBTIResult(m)).toList();
    final bdiResults = bdiMemories.map((m) => _memoryToBDIResult(m)).toList();

    final personalityTypeHistory = <String, int>{};
    for (final result in mbtiResults) {
      personalityTypeHistory[result.personalityType] = 
        (personalityTypeHistory[result.personalityType] ?? 0) + 1;
    }

    final avgBDI = bdiResults.isEmpty 
      ? 0.0 
      : bdiResults.map((r) => r.totalScore).reduce((a, b) => a + b) / bdiResults.length;

    return PsychologyAnalytics(
      totalMBTITests: mbtiResults.length,
      totalBDITests: bdiResults.length,
      latestMBTI: mbtiResults.isNotEmpty ? mbtiResults.last : null,
      latestBDI: bdiResults.isNotEmpty ? bdiResults.last : null,
      bdiHistory: bdiResults,
      personalityTypeHistory: personalityTypeHistory,
      averageBDIScore: avgBDI,
      personalityInsights: _generatePersonalityInsights(mbtiResults, bdiResults),
    );
  }

  // Helper methods
  Future<void> _storeMBTIResult(MBTIResult result) async {
    final memory = Memory(
      id: result.id,
      content: result.toMemoryContent(), // This is now Map<String, dynamic>
      timestamp: result.timestamp,
      tags: ['psychology', 'personality', 'mbti'],
      contexts: ['psychology', 'personality', 'mbti'],
      emotionalWeight: 0.7,
      source: 'psychology',
      type: 'mbti_result',
      importance: 0.9, // High importance for personality data
      metadata: {},
    );
    await _littleBrainRepository.addMemory(memory);
  }

  Future<void> _storeBDIResult(BDIResult result) async {
    final memory = Memory(
      id: result.id,
      content: result.toMemoryContent(), // This is now Map<String, dynamic>
      timestamp: result.timestamp,
      tags: ['psychology', 'mental_health', 'depression'],
      contexts: ['psychology', 'mental_health', 'depression'],
      emotionalWeight: result.needsCrisisIntervention ? 0.9 : 0.6,
      source: 'psychology',
      type: 'bdi_result',
      importance: result.needsCrisisIntervention ? 1.0 : 0.8,
      metadata: {},
    );
    await _littleBrainRepository.addMemory(memory);
  }

  String _getMBTIDescription(String type) {
    const descriptions = {
      'INTJ': 'Arsitek - Pemikir strategis dengan visi yang jelas.',
      'INTP': 'Pemikir - Inovator yang suka mencari kebenaran.',
      'ENTJ': 'Komandan - Pemimpin yang tegas dan efisien.',
      'ENTP': 'Debater - Pemikir kreatif yang suka tantangan.',
      'INFJ': 'Advokat - Idealis dengan empati tinggi.',
      'INFP': 'Mediator - Kreatif dengan nilai-nilai yang kuat.',
      'ENFJ': 'Protagonis - Pemimpin yang menginspirasi.',
      'ENFP': 'Aktivis - Antusias dan kreatif.',
      'ISTJ': 'Logistik - Praktis dan dapat diandalkan.',
      'ISFJ': 'Pelindung - Hangat dan bertanggung jawab.',
      'ESTJ': 'Eksekutif - Terorganisir dan tegas.',
      'ESFJ': 'Konsul - Peduli dan kooperatif.',
      'ISTP': 'Virtuoso - Praktis dan adaptif.',
      'ISFP': 'Petualang - Fleksibel dan ramah.',
      'ESTP': 'Pengusaha - Energik dan spontan.',
      'ESFP': 'Entertainer - Antusias dan spontan.',
    };
    return descriptions[type] ?? 'Tipe kepribadian unik';
  }

  List<String> _getMBTIStrengths(String type) {
    const strengths = {
      'INTJ': ['Strategis', 'Independen', 'Visioner', 'Analitis'],
      'INTP': ['Kreatif', 'Logis', 'Fleksibel', 'Inovatif'],
      'ENTJ': ['Kepemimpinan', 'Efisien', 'Strategis', 'Tegas'],
      'ENTP': ['Kreatif', 'Energik', 'Fleksibel', 'Inovatif'],
      'INFJ': ['Empati', 'Intuitif', 'Idealis', 'Inspiratif'],
      'INFP': ['Kreatif', 'Autentik', 'Empati', 'Fleksibel'],
      'ENFJ': ['Karismatik', 'Empati', 'Inspiratif', 'Terorganisir'],
      'ENFP': ['Antusias', 'Kreatif', 'Empati', 'Fleksibel'],
      'ISTJ': ['Dapat diandalkan', 'Praktis', 'Terorganisir', 'Loyal'],
      'ISFJ': ['Perhatian', 'Dapat diandalkan', 'Empati', 'Detail'],
      'ESTJ': ['Kepemimpinan', 'Terorganisir', 'Praktis', 'Tegas'],
      'ESFJ': ['Kooperatif', 'Empati', 'Terorganisir', 'Loyal'],
      'ISTP': ['Praktis', 'Adaptif', 'Logis', 'Tenang'],
      'ISFP': ['Artistik', 'Fleksibel', 'Empati', 'Realistis'],
      'ESTP': ['Energik', 'Praktis', 'Spontan', 'Adaptif'],
      'ESFP': ['Antusias', 'Spontan', 'Empati', 'Praktis'],
    };
    return strengths[type] ?? ['Unik', 'Spesial'];
  }

  List<String> _getMBTIWeaknesses(String type) {
    const weaknesses = {
      'INTJ': ['Perfeksionis', 'Kurang sosial', 'Kritis', 'Tidak fleksibel'],
      'INTP': ['Procrastination', 'Tidak praktis', 'Kurang detail', 'Tidak sosial'],
      'ENTJ': ['Tidak sabar', 'Dominan', 'Tidak empati', 'Workaholic'],
      'ENTP': ['Tidak fokus', 'Tidak detail', 'Argumentatif', 'Tidak konsisten'],
      'INFJ': ['Perfeksionis', 'Sensitif', 'Burn out', 'Menghindari konflik'],
      'INFP': ['Idealis berlebihan', 'Sensitif', 'Procrastination', 'Tidak praktis'],
      'ENFJ': ['Terlalu altruistik', 'Sensitif kritik', 'Burn out', 'Manipulatif'],
      'ENFP': ['Tidak fokus', 'Terlalu optimis', 'Tidak detail', 'Emotional'],
      'ISTJ': ['Tidak fleksibel', 'Menolak perubahan', 'Tidak kreatif', 'Terlalu serius'],
      'ISFJ': ['Terlalu altruistik', 'Menghindari konflik', 'Tidak tegas', 'Burn out'],
      'ESTJ': ['Tidak fleksibel', 'Tidak empati', 'Workaholic', 'Kontrol'],
      'ESFJ': ['Terlalu altruistik', 'Sensitif kritik', 'Tidak tegas', 'Konformis'],
      'ISTP': ['Tidak ekspresif', 'Tidak komitmen', 'Tidak sosial', 'Mudah bosan'],
      'ISFP': ['Terlalu sensitif', 'Tidak tegas', 'Tidak ambisius', 'Menghindari konflik'],
      'ESTP': ['Impulsif', 'Tidak fokus', 'Tidak sabar', 'Mengambil risiko'],
      'ESFP': ['Tidak fokus', 'Sensitif kritik', 'Tidak terorganisir', 'Impulsif'],
    };
    return weaknesses[type] ?? ['Perlu pengembangan'];
  }

  List<String> _getMBTICareers(String type) {
    const careers = {
      'INTJ': ['Arsitek', 'Engineer', 'Scientist', 'Konsultan'],
      'INTP': ['Programmer', 'Researcher', 'Professor', 'Analyst'],
      'ENTJ': ['CEO', 'Manager', 'Lawyer', 'Consultant'],
      'ENTP': ['Entrepreneur', 'Consultant', 'Journalist', 'Inventor'],
      'INFJ': ['Counselor', 'Writer', 'Teacher', 'Psychologist'],
      'INFP': ['Writer', 'Artist', 'Counselor', 'Teacher'],
      'ENFJ': ['Teacher', 'Counselor', 'Manager', 'Coach'],
      'ENFP': ['Journalist', 'Counselor', 'Teacher', 'Artist'],
      'ISTJ': ['Accountant', 'Manager', 'Administrator', 'Engineer'],
      'ISFJ': ['Nurse', 'Teacher', 'Social Worker', 'Administrator'],
      'ESTJ': ['Manager', 'Administrator', 'Supervisor', 'Executive'],
      'ESFJ': ['Teacher', 'Nurse', 'Social Worker', 'Manager'],
      'ISTP': ['Mechanic', 'Engineer', 'Pilot', 'Police'],
      'ISFP': ['Artist', 'Musician', 'Designer', 'Nurse'],
      'ESTP': ['Sales', 'Police', 'Paramedic', 'Entrepreneur'],
      'ESFP': ['Entertainer', 'Teacher', 'Social Worker', 'Sales'],
    };
    return careers[type] ?? ['Berbagai bidang'];
  }

  DepressionLevel _getBDILevel(int score) {
    if (score <= 9) return DepressionLevel.minimal;
    if (score <= 18) return DepressionLevel.mild;
    if (score <= 29) return DepressionLevel.moderate;
    return DepressionLevel.severe;
  }

  String _getBDIDescription(DepressionLevel level, int score) {
    switch (level) {
      case DepressionLevel.minimal:
        return 'Skor Anda ($score) menunjukkan tingkat depresi minimal. Ini adalah kondisi yang normal.';
      case DepressionLevel.mild:
        return 'Skor Anda ($score) menunjukkan depresi ringan. Mungkin Anda mengalami beberapa gejala yang perlu diperhatikan.';
      case DepressionLevel.moderate:
        return 'Skor Anda ($score) menunjukkan depresi sedang. Disarankan untuk berkonsultasi dengan profesional.';
      case DepressionLevel.severe:
        return 'Skor Anda ($score) menunjukkan depresi berat. Sangat disarankan untuk segera mencari bantuan profesional.';
    }
  }

  List<String> _getBDIRecommendations(DepressionLevel level) {
    switch (level) {
      case DepressionLevel.minimal:
        return [
          'Pertahankan aktivitas positif',
          'Lakukan olahraga rutin',
          'Jaga pola tidur yang sehat',
          'Lakukan hobi yang menyenangkan',
        ];
      case DepressionLevel.mild:
        return [
          'Lakukan aktivitas fisik secara teratur',
          'Praktikkan mindfulness atau meditasi',
          'Jaga pola makan yang sehat',
          'Bicarakan perasaan dengan orang terdekat',
          'Pertimbangkan konseling jika gejala berlanjut',
        ];
      case DepressionLevel.moderate:
        return [
          'Konsultasi dengan psikolog atau psikiater',
          'Ikuti terapi psikologi (CBT, dll)',
          'Pertimbangkan support group',
          'Jaga rutinitas harian yang terstruktur',
          'Lakukan aktivitas yang memberikan makna',
        ];
      case DepressionLevel.severe:
        return [
          'SEGERA konsultasi dengan psikiater',
          'Pertimbangkan terapi intensif',
          'Hubungi hotline crisis jika diperlukan',
          'Minta dukungan dari keluarga dan teman',
          'Jangan ragu untuk mencari bantuan darurat',
        ];
    }
  }

  List<String> _generatePersonalityInsights(List<MBTIResult> mbtiResults, List<BDIResult> bdiResults) {
    final insights = <String>[];
    
    if (mbtiResults.isNotEmpty) {
      final latest = mbtiResults.last;
      insights.add('Tipe kepribadian Anda: ${latest.personalityType}');
      insights.add('Kekuatan utama: ${latest.strengths.join(", ")}');
    }
    
    if (bdiResults.length > 1) {
      final recent = bdiResults.length >= 2 
        ? bdiResults.sublist(bdiResults.length - 2)
        : bdiResults;
      if (recent[1].totalScore < recent[0].totalScore) {
        insights.add('Kondisi mental Anda menunjukkan perbaikan');
      } else if (recent[1].totalScore > recent[0].totalScore) {
        insights.add('Perhatikan kondisi mental Anda, ada indikasi penurunan');
      }
    }
    
    return insights;
  }

  MBTIResult _memoryToMBTIResult(Memory memory) {
    final content = memory.content as Map<String, dynamic>;
    return MBTIResult(
      id: memory.id,
      timestamp: memory.timestamp,
      personalityType: content['personality_type'],
      scores: Map<String, int>.from(content['scores']),
      description: content['description'],
      strengths: List<String>.from(content['strengths']),
      weaknesses: List<String>.from(content['weaknesses']),
      careers: List<String>.from(content['careers']),
      metadata: content['metadata'],
    );
  }

  BDIResult _memoryToBDIResult(Memory memory) {
    final content = memory.content as Map<String, dynamic>;
    return BDIResult(
      id: memory.id,
      timestamp: memory.timestamp,
      totalScore: content['total_score'],
      level: DepressionLevel.values.firstWhere((e) => e.name == content['level']),
      description: content['description'],
      recommendations: List<String>.from(content['recommendations']),
      needsCrisisIntervention: content['needs_crisis_intervention'],
      categoryScores: content['category_scores'] != null 
        ? Map<String, int>.from(content['category_scores'])
        : null,
      metadata: content['metadata'],
    );
  }
}
