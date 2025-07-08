import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_constants.dart';

class HomeTabView extends StatelessWidget {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWelcomeHeader(context),
          const SizedBox(height: AppConstants.largePadding),
          
          // AI Curated Content Sections
          _buildMusicRecommendations(context),
          const SizedBox(height: AppConstants.largePadding),
          
          _buildArticlesSection(context),
          const SizedBox(height: AppConstants.largePadding),
          
          _buildDailyQuote(context),
          const SizedBox(height: AppConstants.largePadding),
          
          _buildJournalSection(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final currentHour = DateTime.now().hour;
    String greeting;
    
    if (currentHour < 12) {
      greeting = 'Selamat Pagi';
    } else if (currentHour < 17) {
      greeting = 'Selamat Siang';
    } else {
      greeting = 'Selamat Malam';
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  'Bagaimana perasaan Anda hari ini?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Symbols.psychology,
            size: 48,
            color: Colors.white,
            fill: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildMusicRecommendations(BuildContext context) {
    return _buildContentSection(
      context,
      title: AppStrings.musicRecommendations,
      icon: Symbols.music_note,
      children: [
        _buildMusicCard(context, 'Lo-fi Hip Hop untuk Fokus', 'Study Playlist', Symbols.headphones),
        _buildMusicCard(context, 'Musik Relaksasi', 'Meditation Mix', Symbols.self_care),
        _buildMusicCard(context, 'Energizing Pop', 'Mood Booster', Symbols.energy_savings_leaf),
      ],
    );
  }

  Widget _buildArticlesSection(BuildContext context) {
    return _buildContentSection(
      context,
      title: AppStrings.articlesForYou,
      icon: Symbols.article,
      children: [
        _buildArticleCard(context, 'Mindfulness dalam Kehidupan Sehari-hari', 'Psychology Today', '5 min read'),
        _buildArticleCard(context, 'Membangun Kebiasaan Positif', 'Self Improvement', '8 min read'),
        _buildArticleCard(context, 'Mengelola Stres dengan Efektif', 'Mental Health', '6 min read'),
      ],
    );
  }

  Widget _buildDailyQuote(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.format_quote,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  AppStrings.dailyQuote,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"Masa depan milik mereka yang percaya pada keindahan impian mereka."',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    '— Eleanor Roosevelt',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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

  Widget _buildJournalSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.edit_note,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  AppStrings.journalEntry,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                  },
                  icon: const Icon(Symbols.add),
                  label: const Text('Tulis'),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Tuliskan pikiran dan perasaan Anda hari ini. Jurnal membantu merefleksikan pengalaman dan meningkatkan kesehatan mental.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildMusicCard(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: IconButton(
          onPressed: () {
          },
          icon: const Icon(Symbols.play_arrow),
        ),
        onTap: () {
        },
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, String title, String source, String readTime) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            Symbols.article,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(
                source,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(' • $readTime'),
          ],
        ),
        trailing: IconButton(
          onPressed: () {
          },
          icon: const Icon(Symbols.arrow_forward),
        ),
        onTap: () {
        },
      ),
    );
  }
}
