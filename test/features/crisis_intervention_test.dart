import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Crisis Detection Logic Tests', () {
    group('Crisis Detection', () {
      test('should detect high-risk keywords', () {
        const message = 'Saya ingin bunuh diri, tidak ada harapan lagi';
        
        final isDetected = _detectCrisisIndicators(message);
        
        expect(isDetected, true);
      });

      test('should detect medium-risk keywords', () {
        const message = 'Saya merasa sangat sedih sekali dan kosong, merasa gagal total';
        
        final isDetected = _detectCrisisIndicators(message);
        
        expect(isDetected, true); // Should detect due to multiple medium-risk keywords
      });

      test('should not detect crisis in normal message', () {
        const message = 'Halo, bagaimana kabar Anda hari ini?';
        
        final isDetected = _detectCrisisIndicators(message);
        
        expect(isDetected, false);
      });

      test('should determine correct crisis level', () {
        const criticalMessage = 'Saya ingin bunuh diri sekarang';
        const highMessage = 'Saya tidak ingin hidup lagi';
        const mediumMessage = 'Saya merasa depresi dan sedih';
        const lowMessage = 'Saya sedikit kesal hari ini';

        expect(_determineCrisisLevel(criticalMessage), 'critical');
        expect(_determineCrisisLevel(highMessage), 'high');
        expect(_determineCrisisLevel(mediumMessage), 'medium');
        expect(_determineCrisisLevel(lowMessage), 'low');
      });

      test('should extract detected keywords correctly', () {
        const message = 'Saya merasa putus asa dan ingin bunuh diri';
        
        final keywords = _getDetectedKeywords(message);
        
        expect(keywords, contains('putus asa'));
        expect(keywords, contains('bunuh diri'));
      });
    });

    group('Intervention Messages', () {
      test('should return critical intervention message for suicide keywords', () {
        const criticalMessage = 'Saya ingin bunuh diri mengakhiri hidup saya';
        final level = _determineCrisisLevel(criticalMessage);
        final interventionMessage = _getInterventionMessage(level);
        
        expect(level, 'critical');
        expect(interventionMessage.contains('🚨'), true);
        expect(interventionMessage.contains('119'), true); // Should contain emergency number
      });

      test('should return appropriate intervention message for depression', () {
        const mediumMessage = 'Saya merasa sangat depresi dan tidak berguna';
        final level = _determineCrisisLevel(mediumMessage);
        final interventionMessage = _getInterventionMessage(level);
        
        expect(interventionMessage.contains('💚'), true);
      });
    });
  });
}

// Helper functions for testing crisis detection logic
bool _detectCrisisIndicators(String text) {
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
    'tidak ada yang peduli', 'nobody cares', 'sendirian', 'alone',
    'sedih', 'kosong', 'gagal' // Add individual words too
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

String _determineCrisisLevel(String text) {
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

List<String> _getDetectedKeywords(String text) {
  final lowercaseText = text.toLowerCase();
  final allKeywords = [
    'bunuh diri', 'suicide', 'mati aja', 'ingin mati', 'tidak ingin hidup',
    'mengakhiri hidup', 'putus asa', 'depresi', 'sedih', 'kosong', 'gagal',
    'hopeless', 'worthless', 'alone', 'sendirian'
  ];

  return allKeywords.where((keyword) => lowercaseText.contains(keyword)).toList();
}

String _getInterventionMessage(String crisisLevel) {
  switch (crisisLevel) {
    case 'critical':
      return '''🚨 Saya sangat peduli dengan perasaan Anda saat ini. Jika Anda memiliki pikiran untuk menyakiti diri sendiri, mohon segera hubungi:

📞 Hotline Crisis Indonesia: 119
📞 Into the Light: 081-1-91-9119

Anda tidak sendirian. Ada bantuan tersedia 24/7. Bisakah Anda menjanjikan untuk tetap aman dan menghubungi salah satu nomor ini?''';
    case 'high':
      return '''💙 Saya mendengar bahwa Anda sedang mengalami masa yang sangat sulit. Perasaan seperti ini bisa sangat berat, tapi ada dukungan yang tersedia:

📞 Hotline Crisis: 119 (24/7)
🤝 Temukan seseorang yang dapat Anda ajak bicara
💚 Pertimbangkan untuk mencari bantuan profesional

Apakah ada yang bisa saya lakukan untuk membantu Anda merasa lebih aman sekarang?''';
    case 'medium':
      return '''💚 Saya mengerti bahwa Anda sedang menghadapi tantangan emosional. Ini hal yang wajar dan Anda tidak sendirian:

🌱 Coba teknik pernapasan dalam
🤝 Hubungi teman atau keluarga
📱 Gunakan aplikasi meditasi atau mindfulness

Jika perasaan ini terus berlanjut, pertimbangkan untuk berbicara dengan konselor. Apakah ada aktivitas yang biasanya membuat Anda merasa lebih baik?''';
    default:
      return '''💙 Saya memahami bahwa Anda mungkin sedang merasa down. Ini adalah bagian normal dari pengalaman manusia:

🌟 Cobalah untuk melakukan sesuatu yang Anda nikmati
🚶‍♀️ Keluar untuk berjalan-jalan sebentar
☕ Minum sesuatu yang hangat
📚 Baca atau dengarkan musik yang menenangkan

Jika Anda ingin berbicara lebih lanjut, saya di sini untuk Anda.''';
  }
}
