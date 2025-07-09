import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../../injection_container.dart';
import '../../domain/usecases/psychology_testing_usecases.dart';
import '../../domain/entities/psychology_entities.dart';

class BDITestWidget extends StatefulWidget {
  const BDITestWidget({super.key});

  @override
  State<BDITestWidget> createState() => _BDITestWidgetState();
}

class _BDITestWidgetState extends State<BDITestWidget> {
  late PsychologyTestingUseCases _psychologyTesting;
  List<BDIQuestion> _questions = [];
  // ignore: prefer_final_fields
  Map<int, int> _answers = {};
  int _currentQuestionIndex = 0;
  bool _isLoading = false;
  BDIResult? _result;

  @override
  void initState() {
    super.initState();
    _psychologyTesting = getIt<PsychologyTestingUseCases>();
    _loadQuestions();
  }

  void _loadQuestions() {
    setState(() {
      _questions = _psychologyTesting.getBDIQuestions();
    });
  }

  void _answerQuestion(int answerIndex) {
    setState(() {
      _answers[_questions[_currentQuestionIndex].id] = answerIndex;
      
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _finishTest();
      }
    });
  }

  Future<void> _finishTest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _psychologyTesting.calculateBDIResult(_answers);
      setState(() {
        _result = result;
        _isLoading = false;
      });
      
      // Show crisis intervention if needed
      if (result.needsCrisisIntervention && mounted) {
        _showCrisisIntervention();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCrisisIntervention() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Symbols.emergency, color: Colors.red, size: 48),
        title: const Text('Perhatian Khusus'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hasil tes menunjukkan Anda mungkin mengalami gejala depresi yang perlu perhatian segera. Sangat disarankan untuk segera berkonsultasi dengan profesional kesehatan mental.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Jika Anda merasa dalam bahaya atau memiliki pikiran untuk menyakiti diri sendiri, segera hubungi:',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '🏥 IGD Rumah Sakit Terdekat\n📞 Hotline Crisis: 119\n💬 Into the Light: 081-1-91-9119',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Saya Mengerti'),
          ),
        ],
      ),
    );
  }

  void _resetTest() {
    setState(() {
      _currentQuestionIndex = 0;
      _answers.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _buildResultView();
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menganalisis kondisi mental Anda...'),
          ],
        ),
      );
    }

    if (_questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildProgressIndicator(),
        const SizedBox(height: 24),
        _buildQuestionView(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    
    return Column(
      children: [
        Text(
          'Pertanyaan ${_currentQuestionIndex + 1} dari ${_questions.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionView() {
    final question = _questions[_currentQuestionIndex];
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.question,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    ...question.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAnswerOption(option, index),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (_currentQuestionIndex > 0)
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentQuestionIndex--;
                  });
                },
                child: const Text('Kembali'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOption(String option, int index) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _answerQuestion(index),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          option,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final result = _result!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: _getResultCardColor(result.level),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getResultIcon(result.level),
                        size: 32,
                        color: _getResultIconColor(result.level),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.level.indonesianDescription,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: _getResultTextColor(result.level),
                              ),
                            ),
                            Text(
                              'Skor: ${result.totalScore}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: _getResultTextColor(result.level),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _getResultTextColor(result.level),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekomendasi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result.recommendations.map((recommendation) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Symbols.lightbulb, 
                          color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(recommendation)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          
          if (result.needsCrisisIntervention) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Symbols.emergency, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Bantuan Darurat',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Jika Anda merasa dalam bahaya atau memiliki pikiran untuk menyakiti diri sendiri:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('🏥 IGD Rumah Sakit Terdekat'),
                    const Text('📞 Hotline Crisis: 119'),
                    const Text('💬 Into the Light: 081-1-91-9119'),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _resetTest,
              child: const Text('Tes Ulang'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getResultCardColor(DepressionLevel level) {
    switch (level) {
      case DepressionLevel.minimal:
        return Colors.green[50]!;
      case DepressionLevel.mild:
        return Colors.yellow[50]!;
      case DepressionLevel.moderate:
        return Colors.orange[50]!;
      case DepressionLevel.severe:
        return Colors.red[50]!;
    }
  }

  IconData _getResultIcon(DepressionLevel level) {
    switch (level) {
      case DepressionLevel.minimal:
        return Symbols.sentiment_very_satisfied;
      case DepressionLevel.mild:
        return Symbols.sentiment_neutral;
      case DepressionLevel.moderate:
        return Symbols.sentiment_dissatisfied;
      case DepressionLevel.severe:
        return Symbols.sentiment_very_dissatisfied;
    }
  }

  Color _getResultIconColor(DepressionLevel level) {
    switch (level) {
      case DepressionLevel.minimal:
        return Colors.green;
      case DepressionLevel.mild:
        return Colors.yellow[700]!;
      case DepressionLevel.moderate:
        return Colors.orange;
      case DepressionLevel.severe:
        return Colors.red;
    }
  }

  Color _getResultTextColor(DepressionLevel level) {
    switch (level) {
      case DepressionLevel.minimal:
        return Colors.green[800]!;
      case DepressionLevel.mild:
        return Colors.yellow[800]!;
      case DepressionLevel.moderate:
        return Colors.orange[800]!;
      case DepressionLevel.severe:
        return Colors.red[800]!;
    }
  }
}
