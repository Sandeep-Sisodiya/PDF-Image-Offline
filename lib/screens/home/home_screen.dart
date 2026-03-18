import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDarkNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryIndigo, AppTheme.accentCyan],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryIndigo.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.description,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ' PDF Image Offline',
                    style: GoogleFonts.publicSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Tools Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Row 1: Image→PDF and PDF→Image
                    Row(
                      children: [
                        Expanded(
                          child: _ToolCard(
                            icon: Icons.image,
                            title: 'Image → PDF',
                            subtitle: 'CONVERT',
                            iconBgColor: AppTheme.primaryIndigo.withValues(alpha: 0.2),
                            iconColor: AppTheme.primaryIndigo,
                            onTap: () {
                              Navigator.pushNamed(context, '/image-to-pdf');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ToolCard(
                            icon: Icons.picture_as_pdf,
                            title: 'PDF → Image',
                            subtitle: 'EXTRACT',
                            iconBgColor: AppTheme.accentCyan.withValues(alpha: 0.2),
                            iconColor: AppTheme.accentCyan,
                            onTap: () {
                              Navigator.pushNamed(context, '/pdf-to-image');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Row 2: Compress Image and Compress PDF
                    Row(
                      children: [
                        Expanded(
                          child: _ToolCard(
                            icon: Icons.photo_size_select_small,
                            title: 'Compress Image',
                            subtitle: 'OPTIMIZE',
                            iconBgColor: AppTheme.primaryIndigo.withValues(alpha: 0.2),
                            iconColor: AppTheme.primaryIndigo,
                            onTap: () {
                              Navigator.pushNamed(context, '/compress-image');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ToolCard(
                            icon: Icons.compress,
                            title: 'Compress PDF',
                            subtitle: 'SHRINK',
                            iconBgColor: AppTheme.accentCyan.withValues(alpha: 0.2),
                            iconColor: AppTheme.accentCyan,
                            onTap: () {
                              Navigator.pushNamed(context, '/compress-pdf');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // History Card (full width)
                    _ToolCard(
                      icon: Icons.history,
                      title: 'History',
                      subtitle: 'RECENT FILES',
                      iconBgColor: const Color(0xFF334155).withValues(alpha: 0.5),
                      iconColor: const Color(0xFFCBD5E1),
                      fullWidth: true,
                      onTap: () => onNavigate(1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final Color iconColor;
  final bool fullWidth;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.iconColor,
    this.fullWidth = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 30, color: iconColor),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.publicSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
