import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../../injection_container.dart';
import '../../../little_brain/domain/repositories/little_brain_repository.dart';

class LifeTreeWidget extends StatefulWidget {
  const LifeTreeWidget({super.key});

  @override
  State<LifeTreeWidget> createState() => _LifeTreeWidgetState();
}

class _LifeTreeWidgetState extends State<LifeTreeWidget> {
  late LittleBrainRepository _littleBrainRepository;
  Map<String, int> _lifeAreas = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _littleBrainRepository = getIt<LittleBrainRepository>();
    _loadLifeData();
  }

  Future<void> _loadLifeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allMemories = await _littleBrainRepository.getAllMemories();
      // Get recent memories (last 100)
      final memories = allMemories.take(100).toList();
      
      // Analyze memories to calculate life area scores
      final areas = <String, List<double>>{
        'Karier': [],
        'Kesehatan': [],
        'Hubungan': [],
        'Pembelajaran': [],
        'Kreativitas': [],
        'Spiritualitas': [],
      };

      for (final memory in memories) {
        final tags = memory.tags;
        final emotionalWeight = memory.emotionalWeight;
        
        // Map tags to life areas
        if (tags.contains('work') || tags.contains('career') || tags.contains('job')) {
          areas['Karier']!.add(emotionalWeight);
        }
        if (tags.contains('health') || tags.contains('exercise') || tags.contains('medical')) {
          areas['Kesehatan']!.add(emotionalWeight);
        }
        if (tags.contains('family') || tags.contains('friends') || tags.contains('relationship')) {
          areas['Hubungan']!.add(emotionalWeight);
        }
        if (tags.contains('learning') || tags.contains('education') || tags.contains('skill')) {
          areas['Pembelajaran']!.add(emotionalWeight);
        }
        if (tags.contains('creative') || tags.contains('art') || tags.contains('music')) {
          areas['Kreativitas']!.add(emotionalWeight);
        }
        if (tags.contains('spiritual') || tags.contains('meditation') || tags.contains('prayer')) {
          areas['Spiritualitas']!.add(emotionalWeight);
        }
      }

      // Calculate average scores
      final scores = <String, int>{};
      areas.forEach((area, values) {
        if (values.isNotEmpty) {
          final average = values.reduce((a, b) => a + b) / values.length;
          scores[area] = ((average + 1) * 50).round().clamp(0, 100); // Convert to 0-100 scale
        } else {
          scores[area] = 50; // Default score
        }
      });

      setState(() {
        _lifeAreas = scores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getAreaColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.amber;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }

  IconData _getAreaIcon(String area) {
    switch (area) {
      case 'Karier':
        return Symbols.work;
      case 'Kesehatan':
        return Symbols.favorite;
      case 'Hubungan':
        return Symbols.group;
      case 'Pembelajaran':
        return Symbols.school;
      case 'Kreativitas':
        return Symbols.palette;
      case 'Spiritualitas':
        return Symbols.self_improvement;
      default:
        return Symbols.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                  Symbols.park,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Pohon Kehidupan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Visualisasi pertumbuhan dan keseimbangan hidup berdasarkan aktivitas dan emosi yang tercatat di Little Brain.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),
            
            // Tree Visualization
            Center(
              child: Column(
                children: [
                  // Crown of the tree (life areas)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTreeBranch('Spiritualitas', _lifeAreas['Spiritualitas'] ?? 50),
                      _buildTreeBranch('Pembelajaran', _lifeAreas['Pembelajaran'] ?? 50),
                      _buildTreeBranch('Kreativitas', _lifeAreas['Kreativitas'] ?? 50),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTreeBranch('Karier', _lifeAreas['Karier'] ?? 50),
                      _buildTreeBranch('Kesehatan', _lifeAreas['Kesehatan'] ?? 50),
                      _buildTreeBranch('Hubungan', _lifeAreas['Hubungan'] ?? 50),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Tree trunk
                  Container(
                    width: 40,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.brown,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  
                  // Roots (overall balance)
                  const SizedBox(height: 8),
                  Icon(
                    Symbols.grass,
                    size: 40,
                    color: Colors.green.shade700,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // Life Areas Details
            Text(
              'Detail Area Kehidupan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            ..._lifeAreas.entries.map((entry) => Container(
              margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAreaColor(entry.value).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getAreaIcon(entry.key),
                      color: _getAreaColor(entry.value),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        LinearProgressIndicator(
                          value: entry.value / 100,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation(_getAreaColor(entry.value)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Text(
                    '${entry.value}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _getAreaColor(entry.value),
                    ),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Symbols.info,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      'Pohon kehidupan diperbarui secara otomatis berdasarkan aktivitas dan emosi yang tercatat dalam percakapan dengan AI.',
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

  Widget _buildTreeBranch(String area, int score) {
    final color = _getAreaColor(score);
    final size = (score / 100 * 30 + 20).clamp(20.0, 50.0); // Size based on score
    
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Icon(
            _getAreaIcon(area),
            color: color,
            size: size * 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          area,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
