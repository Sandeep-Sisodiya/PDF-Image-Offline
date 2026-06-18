import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// A premium loading overlay that matches the app's dark glassmorphism design.
///
/// Shows a pulsing icon, animated progress indicator, and rotating status
/// messages with smooth fade transitions. Designed to be placed in a [Stack]
/// on top of screen content.
class LoadingOverlay extends StatefulWidget {
  /// The accent color for the spinner and icon (indigo for images, cyan for PDFs).
  final Color accentColor;

  /// The icon to display in the center of the overlay.
  final IconData icon;

  /// Status messages to cycle through with fade animation.
  final List<String> messages;

  /// Duration to show each message before transitioning to the next.
  final Duration messageDuration;

  const LoadingOverlay({
    super.key,
    required this.accentColor,
    required this.icon,
    required this.messages,
    this.messageDuration = const Duration(milliseconds: 2200),
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _fadeInController;
  late final Animation<double> _fadeInAnimation;
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();

    // Pulsing scale animation for the icon container
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade-in for the entire overlay
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    );

    // Start cycling messages
    if (widget.messages.length > 1) {
      _messageTimer = Timer.periodic(widget.messageDuration, (_) {
        if (mounted) {
          setState(() {
            _currentMessageIndex =
                (_currentMessageIndex + 1) % widget.messages.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _pulseController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Container(
        color: AppTheme.backgroundDarkNavy.withValues(alpha: 0.85),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.08),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing icon with ring
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accentColor.withValues(alpha: 0.15),
                        border: Border.all(
                          color: widget.accentColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 32,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Circular progress indicator
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: widget.accentColor,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Animated status message
                  SizedBox(
                    height: 22,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        widget.messages.isNotEmpty
                            ? widget.messages[_currentMessageIndex]
                            : 'Loading...',
                        key: ValueKey<int>(_currentMessageIndex),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.publicSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
