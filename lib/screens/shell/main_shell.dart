import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigate: _onNavigate),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    // Different background colors for each screen
    final bgColors = [
      AppTheme.backgroundDarkNavy,
      AppTheme.backgroundDarkBrown,
      AppTheme.backgroundDarkBrownSettings,
    ];

    // Different accent colors for active nav item
    final activeColors = [
      AppTheme.primaryIndigo,
      AppTheme.primaryOrange,
      AppTheme.primaryOrange,
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColors[_currentIndex].withValues(alpha: 0.8),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  icon: Icons.home,
                  filledIcon: Icons.home,
                  label: _currentIndex == 0 ? 'Home' : 'HOME',
                  isActive: _currentIndex == 0,
                  activeColor: activeColors[_currentIndex],
                  onTap: () => _onNavigate(0),
                ),
                _NavItem(
                  icon: Icons.history,
                  filledIcon: Icons.history,
                  label: _currentIndex == 1 ? 'History' : 'HISTORY',
                  isActive: _currentIndex == 1,
                  activeColor: activeColors[_currentIndex],
                  onTap: () => _onNavigate(1),
                ),
                _NavItem(
                  icon: Icons.settings,
                  filledIcon: Icons.settings,
                  label: _currentIndex == 2 ? 'Settings' : 'SETTINGS',
                  isActive: _currentIndex == 2,
                  activeColor: activeColors[_currentIndex],
                  onTap: () => _onNavigate(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData filledIcon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.filledIcon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? filledIcon : icon,
            color: isActive ? activeColor : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.publicSans(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? activeColor : Colors.grey[600],
              letterSpacing: isActive ? 0 : 1,
            ),
          ),
        ],
      ),
    );
  }
}
