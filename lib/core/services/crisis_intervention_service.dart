import 'package:persona_ai_assistant/core/services/backend_api_service.dart';
import 'package:persona_ai_assistant/core/models/crisis_models.dart';
import 'package:persona_ai_assistant/injection_container.dart';

/// Crisis intervention service that manages crisis detection, logging, and intervention
class CrisisInterventionService {
  static final CrisisInterventionService _instance = CrisisInterventionService._internal();
  factory CrisisInterventionService() => _instance;
  CrisisInterventionService._internal();

  final BackendApiService _backendApi = getIt<BackendApiService>();

  /// Log a crisis event to the backend
  Future<void> logCrisisEvent({
    required String crisisLevel,
    required String triggerSource,
    required List<String> detectedKeywords,
    String? userMessage,
  }) async {
    try {
      await _backendApi.logCrisisEvent(
        crisisLevel: crisisLevel,
        triggerSource: triggerSource,
        detectedKeywords: detectedKeywords,
        userMessage: userMessage,
      );
    } catch (e) {
      // Log locally if backend fails
      print('Crisis event logging failed: $e');
      // Could store locally and sync later
    }
  }

  /// Record intervention details
  Future<void> recordIntervention({
    required String crisisEventId,
    required String interventionType,
    List<String>? resourcesProvided,
    bool professionalContactMade = false,
  }) async {
    try {
      await _backendApi.recordIntervention(
        crisisEventId: crisisEventId,
        interventionType: interventionType,
        resourcesProvided: resourcesProvided ?? [],
        professionalContactMade: professionalContactMade,
      );
    } catch (e) {
      print('Intervention recording failed: $e');
    }
  }

  /// Get crisis history for the user
  Future<List<CrisisEvent>> getCrisisHistory() async {
    try {
      return await _backendApi.getCrisisHistory();
    } catch (e) {
      print('Failed to get crisis history: $e');
      return [];
    }
  }

  /// Get crisis resources and hotlines
  Future<CrisisResources> getCrisisResources({String language = 'id'}) async {
    try {
      return await _backendApi.getCrisisResources(language: language);
    } catch (e) {
      print('Failed to get crisis resources: $e');
      // Return default Indonesian resources
      return _getDefaultIndonesianResources();
    }
  }

  /// Detect crisis indicators in text
  bool detectCrisisIndicators(String text) {
    final lowercaseText = text.toLowerCase();
    
    // High-risk keywords
    final highRiskKeywords = [
      'bunuh diri', 'suicide', 'mati aja', 'ingin mati', 'tidak ingin hidup',
      'mengakhiri hidup', 'finish myself', 'end it all', 'tidak ada harapan',
      'hopeless', 'putus asa', 'depresi berat', 'severe depression'
    ];

    // Medium-risk keywords
    final mediumRiskKeywords = [
      'sedih sekali', 'very sad', 'merasa kosong', 'feel empty',
      'tidak berguna', 'worthless', 'gagal total', 'complete failure',
      'tidak ada yang peduli', 'nobody cares', 'sendirian', 'alone'
    ];

    // Check for high-risk indicators
    for (String keyword in highRiskKeywords) {
      if (lowercaseText.contains(keyword)) {
        return true;
      }
    }

    // Check for multiple medium-risk indicators
    int mediumRiskCount = 0;
    for (String keyword in mediumRiskKeywords) {
      if (lowercaseText.contains(keyword)) {
        mediumRiskCount++;
      }
    }

    return mediumRiskCount >= 2;
  }

  /// Determine crisis level based on text analysis
  String determineCrisisLevel(String text) {
    final lowercaseText = text.toLowerCase();
    
    final criticalKeywords = [
      'bunuh diri', 'suicide', 'mati aja', 'ingin mati'
    ];

    final highKeywords = [
      'tidak ingin hidup', 'mengakhiri hidup', 'putus asa total'
    ];

    final mediumKeywords = [
      'depresi', 'sedih', 'kosong', 'gagal', 'hopeless'
    ];

    for (String keyword in criticalKeywords) {
      if (lowercaseText.contains(keyword)) {
        return 'critical';
      }
    }

    for (String keyword in highKeywords) {
      if (lowercaseText.contains(keyword)) {
        return 'high';
      }
    }

    for (String keyword in mediumKeywords) {
      if (lowercaseText.contains(keyword)) {
        return 'medium';
      }
    }

    return 'low';
  }

  /// Get detected keywords from text
  List<String> getDetectedKeywords(String text) {
    final lowercaseText = text.toLowerCase();
    final allKeywords = [
      'bunuh diri', 'suicide', 'mati aja', 'ingin mati', 'tidak ingin hidup',
      'mengakhiri hidup', 'putus asa', 'depresi', 'sedih', 'kosong', 'gagal',
      'hopeless', 'worthless', 'alone', 'sendirian'
    ];

    return allKeywords.where((keyword) => lowercaseText.contains(keyword)).toList();
  }

  /// Handle crisis detection and intervention
  Future<String?> handleCrisisDetection(String text, String source) async {
    if (!detectCrisisIndicators(text)) {
      return null;
    }

    final crisisLevel = determineCrisisLevel(text);
    final detectedKeywords = getDetectedKeywords(text);

    // Log crisis event
    await logCrisisEvent(
      crisisLevel: crisisLevel,
      triggerSource: source,
      detectedKeywords: detectedKeywords,
      userMessage: text,
    );

    // Return intervention message based on crisis level
    switch (crisisLevel) {
      case 'critical':
        return _getCriticalInterventionMessage();
      case 'high':
        return _getHighInterventionMessage();
      case 'medium':
        return _getMediumInterventionMessage();
      default:
        return _getLowInterventionMessage();
    }
  }

  String _getCriticalInterventionMessage() {
    return '''🚨 Saya sangat peduli dengan perasaan Anda saat ini. Jika Anda memiliki pikiran untuk menyakiti diri sendiri, mohon segera hubungi:

📞 Hotline Crisis Indonesia: 119
📞 Into the Light: 081-1-91-9119

Anda tidak sendirian. Ada bantuan tersedia 24/7. Bisakah Anda menjanjikan untuk tetap aman dan menghubungi salah satu nomor ini?''';
  }

  String _getHighInterventionMessage() {
    return '''💙 Saya mendengar bahwa Anda sedang mengalami masa yang sangat sulit. Perasaan seperti ini bisa sangat berat, tapi ada dukungan yang tersedia:

📞 Hotline Crisis: 119 (24/7)
🤝 Temukan seseorang yang dapat Anda ajak bicara
💚 Pertimbangkan untuk mencari bantuan profesional

Apakah ada yang bisa saya lakukan untuk membantu Anda merasa lebih aman sekarang?''';
  }

  String _getMediumInterventionMessage() {
    return '''💚 Saya mengerti bahwa Anda sedang menghadapi tantangan emosional. Ini hal yang wajar dan Anda tidak sendirian:

🌱 Coba teknik pernapasan dalam
🤝 Hubungi teman atau keluarga
📱 Gunakan aplikasi meditasi atau mindfulness

Jika perasaan ini terus berlanjut, pertimbangkan untuk berbicara dengan konselor. Apakah ada aktivitas yang biasanya membuat Anda merasa lebih baik?''';
  }

  String _getLowInterventionMessage() {
    return '''💙 Saya memahami bahwa Anda mungkin sedang merasa down. Ini adalah bagian normal dari pengalaman manusia:

🌟 Cobalah untuk melakukan sesuatu yang Anda nikmati
🚶‍♀️ Keluar untuk berjalan-jalan sebentar
☕ Minum sesuatu yang hangat
📚 Baca atau dengarkan musik yang menenangkan

Jika Anda ingin berbicara lebih lanjut, saya di sini untuk Anda.''';
  }

  CrisisResources _getDefaultIndonesianResources() {
    return CrisisResources(
      hotlines: [
        CrisisHotline(
          name: 'Hotline Crisis Indonesia',
          number: '119',
          description: 'Layanan darurat nasional 24/7',
          available: '24/7',
        ),
        CrisisHotline(
          name: 'Into the Light',
          number: '081-1-91-9119',
          description: 'Konseling untuk pencegahan bunuh diri',
          available: '24/7',
        ),
      ],
      emergencyContacts: [
        EmergencyContact(
          name: 'Rumah Sakit Jiwa',
          number: '118',
          description: 'Emergency mental health services',
        ),
      ],
      mentalHealthResources: [
        MentalHealthResource(
          name: 'Sehat Mental',
          url: 'https://sehatmental.kemkes.go.id',
          description: 'Platform kesehatan mental pemerintah',
        ),
      ],
      selfCareGuides: [
        SelfCareGuide(
          title: 'Teknik Pernapasan',
          description: 'Panduan pernapasan untuk mengurangi kecemasan',
          steps: [
            'Tarik napas dalam selama 4 detik',
            'Tahan napas selama 7 detik',
            'Keluarkan napas selama 8 detik',
            'Ulangi 4-6 kali',
          ],
        ),
      ],
    );
  }
}
