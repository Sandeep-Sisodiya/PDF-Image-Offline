import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/history_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDarkBrownSettings,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // PREFERENCES Section
                  _buildSectionTitle('PREFERENCES'),
                  const SizedBox(height: 12),
                  _buildDarkModeToggle(context),
                  const SizedBox(height: 8),
                  _buildQualitySelector(context),
                  const SizedBox(height: 28),
                  // DATA & STORAGE Section
                  _buildSectionTitle('DATA & STORAGE'),
                  const SizedBox(height: 12),
                  _buildStorageCard(context),
                  const SizedBox(height: 32),
                  // Version Info
                  Center(
                    child: Text(
                      'DOCUMASTER VERSION 2.4.1 (BUILD 820)',
                      style: GoogleFonts.publicSans(
                        fontSize: 10,
                        color: Colors.grey[600],
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 8, 48, 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDarkBrownSettings,
        border: Border(
          bottom: BorderSide(color: const Color(0xFF334155).withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {},
          ),
          Expanded(
            child: Center(
              child: Text(
                'Settings',
                style: GoogleFonts.publicSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: GoogleFonts.publicSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF334155).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dark_mode,
                  color: AppTheme.primaryOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dark Mode',
                      style: GoogleFonts.publicSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Adjust system appearance',
                      style: GoogleFonts.publicSans(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.isDarkMode,
                onChanged: (value) => settings.toggleDarkMode(),
                activeColor: AppTheme.primaryOrange,
                activeTrackColor: AppTheme.primaryOrange.withValues(alpha: 0.5),
                inactiveThumbColor: Colors.grey[400],
                inactiveTrackColor: Colors.grey[700],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualitySelector(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF334155).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.high_quality,
                      color: AppTheme.primaryOrange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Scan Quality',
                        style: GoogleFonts.publicSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select output resolution',
                        style: GoogleFonts.publicSans(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: ['Low', 'Medium', 'High'].map((quality) {
                    final isSelected = settings.quality == quality;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => settings.setQuality(quality),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF334155)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                            border: isSelected
                                ? Border.all(
                                    color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              quality,
                              style: GoogleFonts.publicSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.primaryOrange
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStorageCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF334155).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.storage,
                    color: AppTheme.primaryOrange,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Storage Used',
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  final usedGB = settings.storageUsed / (1024 * 1024 * 1024);
                  return Text(
                    '${usedGB.toStringAsFixed(1)} GB of 5 GB',
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              final percentage = settings.storageUsed / (5 * 1024 * 1024 * 1024);
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: const Color(0xFF0F172A),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryOrange),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Clear Cache Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Clear Cache?',
                      style: GoogleFonts.publicSans(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    content: Text(
                      'This will delete all converted and compressed files.',
                      style: GoogleFonts.publicSans(color: Colors.grey[400]),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.publicSans(color: Colors.grey[400]),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Clear',
                          style: GoogleFonts.publicSans(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await context.read<HistoryProvider>().clearAll();
                  await context.read<SettingsProvider>().clearCache();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Cache cleared!'),
                        backgroundColor: AppTheme.primaryOrange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.cleaning_services, size: 16),
              label: Text(
                'Clear Cache',
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryOrange,
                side: BorderSide(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
