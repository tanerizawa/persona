import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../../injection_container.dart';
import '../../domain/usecases/psychology_testing_usecases.dart';
import '../../domain/entities/psychology_entities.dart';

class MBTITestWidget extends StatefulWidget {
  const MBTITestWidget({super.key});

  @override
  State<MBTITestWidget> createState() => _MBTITestWidgetState();
}

class _MBTITestWidgetState extends State<MBTITestWidget> {
  late PsychologyTestingUseCases _psychologyTesting;
  List<MBTIQuestion> _questions = [];
  // ignore: prefer_final_fields
  Map<int, bool> _answers = {};
  int _currentQuestionIndex = 0;
  bool _isLoading = false;
  MBTIResult? _result;

  @override
  void initState() {
    super.initState();
    _psychologyTesting = getIt<PsychologyTestingUseCases>();
    _loadQuestions();
  }

  void _loadQuestions() {
    setState(() {
      _questions = _psychologyTesting.getMBTIQuestions();
    });
  }

  void _answerQuestion(bool answer) {
    setState(() {
      _answers[_questions[_currentQuestionIndex].id] = answer;
      
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
      final result = await _psychologyTesting.calculateMBTIResult(_answers);
      setState(() {
        _result = result;
        _isLoading = false;
      });
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
            Text('Menganalisis kepribadian Anda...'),
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
                    _buildAnswerOption(question.optionA, true),
                    const SizedBox(height: 12),
                    _buildAnswerOption(question.optionB, false),
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

  Widget _buildAnswerOption(String option, bool isOptionA) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _answerQuestion(isOptionA),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          option,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
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
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Symbols.psychology,
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tipe Kepribadian: ${result.personalityType}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.description,
                    style: Theme.of(context).textTheme.bodyLarge,
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
                    'Kekuatan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result.strengths.map((strength) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Symbols.check_circle, 
                          color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(strength),
                      ],
                    ),
                  )),
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
                    'Area Pengembangan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result.weaknesses.map((weakness) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Symbols.info, 
                          color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(weakness)),
                      ],
                    ),
                  )),
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
                    'Karir yang Cocok',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result.careers.map((career) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Symbols.work, 
                          color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Text(career),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          
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
}
