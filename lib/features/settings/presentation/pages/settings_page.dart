import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_constants.dart';
import '../widgets/sync_status_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _personalityAnalysisEnabled = true;
  bool _dataBackupEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTab),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(context),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // App Settings
            _buildAppSettings(context),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // Privacy & Security
            _buildPrivacySettings(context),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // Little Brain Settings
            _buildLittleBrainSettings(context),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // Sync Status
            const SyncStatusWidget(),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // Support & About
            _buildSupportSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.profile,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Symbols.person,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengguna Persona',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bergabung sejak Juli 2025',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.smallPadding,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'INFP - The Mediator',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                  },
                  icon: const Icon(Symbols.edit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan Aplikasi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            _buildSettingsItem(
              context,
              title: AppStrings.notifications,
              subtitle: 'Pengingat mood, tes, dan aktivitas',
              icon: Symbols.notifications,
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ),
            
            _buildSettingsItem(
              context,
              title: 'Mode Gelap',
              subtitle: 'Mengikuti pengaturan sistem',
              icon: Symbols.dark_mode,
              trailing: Switch(
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value;
                  });
                },
              ),
            ),
            
            _buildSettingsItem(
              context,
              title: 'Bahasa',
              subtitle: 'Bahasa Indonesia',
              icon: Symbols.language,
              onTap: () {
              },
            ),
            
            _buildSettingsItem(
              context,
              title: 'Backup Data',
              subtitle: 'Sinkronisasi otomatis ke cloud',
              icon: Symbols.cloud_sync,
              trailing: Switch(
                value: _dataBackupEnabled,
                onChanged: (value) {
                  setState(() {
                    _dataBackupEnabled = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privasi & Keamanan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            _buildSettingsItem(
              context,
              title: 'Kebijakan Privasi',
              subtitle: 'Lihat bagaimana kami melindungi data Anda',
              icon: Symbols.privacy_tip,
              onTap: () {
              },
            ),
            
            _buildSettingsItem(
              context,
              title: 'Kelola Data',
              subtitle: 'Export, hapus, atau kelola data pribadi',
              icon: Symbols.database,
              onTap: () {
              },
            ),
            
            _buildSettingsItem(
              context,
              title: 'Izin Aplikasi',
              subtitle: 'Kelola izin kamera, mikrofon, dan lainnya',
              icon: Symbols.security,
              onTap: () {
              },
            ),
            
            _buildSettingsItem(
              context,
              title: 'API OpenRouter',
              subtitle: 'Konfigurasi koneksi AI',
              icon: Symbols.key,
              onTap: () {
                _showAPISettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLittleBrainSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.psychology,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Otak Kecil',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Pengaturan untuk sistem memori jangka panjang dan pemodelan kepribadian AI.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            _buildSettingsItem(
              context,
              title: 'Analisis Kepribadian',
              subtitle: 'Izinkan AI menganalisis pola perilaku',
              icon: Symbols.analytics,
              trailing: Switch(
                value: _personalityAnalysisEnabled,
                onChanged: (value) {
                  setState(() {
                    _personalityAnalysisEnabled = value;
                  });
                },
              ),
            ),
            
            _buildSettingsItem(
              context,
              title: 'Memori & Kenangan',
              subtitle: 'Lihat data yang disimpan oleh Otak Kecil',
              icon: Symbols.memory,
              onTap: () {
              },
            ),
            
            _buildSettingsItem(
              context,
              title: 'Reset Pembelajaran',
              subtitle: 'Hapus semua data pembelajaran AI',
              icon: Symbols.restart_alt,
              onTap: () {
                _showResetDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dukungan & Tentang',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            _buildSettingsItem(
              context,
              title: 'Bantuan & FAQ',
              subtitle: 'Pertanyaan yang sering diajukan',
              icon: Symbols.help,
              onTap: () {
              },
            ),
            
            _buildSettingsItem(
              context,
              title: 'Hubungi Kami',
              subtitle: 'Kirim feedback atau laporkan masalah',
              icon: Symbols.contact_support,
              onTap: () {
              },
            ),
            
            _buildSettingsItem(
              context,
              title: 'Tentang Persona',
              subtitle: 'Versi ${AppConstants.appVersion}',
              icon: Symbols.info,
              onTap: () {
                _showAboutDialog();
              },
            ),
            
            _buildSettingsItem(
              context,
              title: 'Syarat & Ketentuan',
              subtitle: 'Ketentuan penggunaan aplikasi',
              icon: Symbols.description,
              onTap: () {
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? (onTap != null ? const Icon(Symbols.arrow_forward) : null),
      onTap: onTap,
    );
  }

  void _showAPISettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengaturan API OpenRouter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Masukkan API key OpenRouter',
              ),
              obscureText: true,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'API key akan digunakan untuk berkomunikasi dengan layanan AI OpenRouter. Pastikan key Anda valid dan memiliki credit yang cukup.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('API key berhasil disimpan'),
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Pembelajaran'),
        content: const Text(
          'Tindakan ini akan menghapus semua data pembelajaran AI dan memulai dari awal. Data ini tidak dapat dipulihkan.\n\nApakah Anda yakin ingin melanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data pembelajaran telah direset'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Icon(
        Symbols.psychology,
        size: 48,
        color: Theme.of(context).primaryColor,
        fill: 1,
      ),
      children: [
        const SizedBox(height: AppConstants.defaultPadding),
        Text(
          'Persona adalah asisten pribadi berbasis AI yang dirancang untuk membantu Anda memahami dan mengembangkan diri melalui teknologi kecerdasan buatan yang canggih.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Text(
          'Dikembangkan dengan ❤️ menggunakan Flutter dan OpenRouter API.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
