import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection/injection.dart';
import '../../domain/usecases/psychology_testing_usecases.dart';
import '../../domain/entities/psychology_entities.dart';
import '../widgets/mbti_test_widget.dart';
import '../widgets/bdi_test_widget.dart';

class PsychologyPage extends StatefulWidget {
  const PsychologyPage({super.key});

  @override
  State<PsychologyPage> createState() => _PsychologyPageState();
}

class _PsychologyPageState extends State<PsychologyPage> {
  late PsychologyTestingUseCases _psychologyTesting;
  PsychologyAnalytics? _analytics;
  bool _isLoadingAnalytics = false;

  @override
  void initState() {
    super.initState();
    _psychologyTesting = getIt<PsychologyTestingUseCases>();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoadingAnalytics = true;
    });

    try {
      final analytics = await _psychologyTesting.getPsychologyAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoadingAnalytics = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAnalytics = false;
      });
    }
  }

  void _startMBTITest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Tes MBTI'),
          ),
          body: const MBTITestWidget(),
        ),
      ),
    ).then((_) => _loadAnalytics()); // Refresh analytics after test
  }

  void _startBDITest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Tes BDI'),
          ),
          body: const BDITestWidget(),
        ),
      ),
    ).then((_) => _loadAnalytics()); // Refresh analytics after test
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil Psikologi',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Memahami kepribadian dan kesehatan mental Anda melalui berbagai tes psikologi yang telah tervalidasi.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Current Personality Profile
          _buildPersonalityProfile(context),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Available Tests
          Text(
            'Tes Psikologi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          
          _buildTestCard(
            context,
            title: 'Tes MBTI',
            subtitle: 'Myers-Briggs Type Indicator',
            description: 'Temukan tipe kepribadian Anda berdasarkan preferensi psikologis dalam cara melihat dunia dan membuat keputusan.',
            icon: Symbols.psychology,
            color: Colors.purple,
            duration: '15-20 menit',
            questions: AppConstants.mbtiQuestionCount,
            onTap: () => _startMBTITest(),
          ),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          _buildTestCard(
            context,
            title: 'Tes BDI',
            subtitle: 'Beck Depression Inventory',
            description: 'Evaluasi tingkat depresi dan kesehatan mental Anda. Hasil akan membantu memahami kondisi emosional saat ini.',
            icon: Symbols.mood,
            color: Colors.blue,
            duration: '5-10 menit',
            questions: AppConstants.bdiQuestionCount,
            onTap: () => _startBDITest(),
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Mental Health Resources
          _buildMentalHealthResources(context),
        ],
      ),
    );
  }

  Widget _buildPersonalityProfile(BuildContext context) {
    if (_isLoadingAnalytics) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.person,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  AppStrings.personalityProfile,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            if (_analytics?.latestMBTI != null) ...[
              Text(
                'Tipe Kepribadian: ${_analytics!.latestMBTI!.personalityType}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _analytics!.latestMBTI!.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            
            if (_analytics?.latestBDI != null) ...[
              Text(
                'Kondisi Mental: ${_analytics!.latestBDI!.level.indonesianDescription}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
            ],
            
            if (_analytics?.personalityInsights.isNotEmpty ?? false) ...[
              Text(
                'Insights:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ..._analytics!.personalityInsights.map((insight) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $insight'),
                ),
              ),
            ] else ...[
              Text(
                'Belum ada data profil kepribadian. Silakan lakukan tes untuk mendapatkan insights tentang diri Anda.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required String duration,
    required int questions,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.smallPadding),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Symbols.arrow_forward),
                ],
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              Row(
                children: [
                  Icon(
                    Symbols.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    duration,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Icon(
                    Symbols.quiz,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$questions pertanyaan',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMentalHealthResources(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.health_and_safety,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Dukungan Kesehatan Mental',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            Text(
              'Jika Anda membutuhkan bantuan professional atau merasa dalam krisis, berikut adalah sumber daya yang tersedia:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            _buildResourceItem(
              context,
              'Hotline Kesehatan Mental',
              '119 (24/7)',
              Symbols.phone,
              Colors.red,
            ),
            _buildResourceItem(
              context,
              'Konsultasi Online',
              'Chat dengan psikolog berlisensi',
              Symbols.chat,
              Colors.blue,
            ),
            _buildResourceItem(
              context,
              'Artikel & Tips',
              'Panduan kesehatan mental sehari-hari',
              Symbols.article,
              Colors.green,
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Symbols.warning,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      'Jika Anda memiliki pikiran untuk menyakiti diri sendiri, segera hubungi layanan darurat atau hotline krisis.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
            },
            icon: const Icon(Symbols.arrow_forward),
          ),
        ],
      ),
    );
  }
}
