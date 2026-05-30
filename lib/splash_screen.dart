import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _brandColor = Color(0xFF4E99B4);
  static const Color _glowColor = Color(0x334E99B4);
  static const Duration _animationDuration = Duration(milliseconds: 1200);
  static const Duration _splashDuration = Duration(seconds: 3);

  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Shake: oscillates between -5.0 and +5.0 pixels
    // We use a sine-based feel by chaining two tweens via an interval curve.
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -5.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -5.0, end: 5.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 5.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_controller);

    // Navigate to /home after the splash duration
    Future.delayed(_splashDuration, _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Text(
            'Bazaar Suez',
            style: TextStyle(
              color: _brandColor,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: const [
                Shadow(
                  color: _glowColor,
                  blurRadius: 24,
                  offset: Offset(0, 4),
                ),
                Shadow(
                  color: _glowColor,
                  blurRadius: 48,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
