import 'dart:math' as math;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const Color _kPrimaryColor = Color(0xFF4E99B4);
const Color _kSecondaryColor = Colors.white;

const Duration _kTotalDuration = Duration(milliseconds: 1900);
const Duration _kIdleDuration = Duration(milliseconds: 3000);

const int _kIgnitionEndMs = 500;
const int _kCircularRevealEndMs = 1100;
const int _kTotalMs = 1900;

const double _kIgnitionMaxRadius = 20;
const double _kIgnitionGlowBlurMax = 48;
const double _kIgnitionGlowSpreadMax = 14;
const double _kIgnitionGlowOpacityMax = 0.85;

const double _kLogoIconSize = 64;
const double _kLogoFontSize = 28;
const double _kLogoSpacing = 12;
const double _kLogoScaleBegin = 0.88;

const int _kParticleCount = 30;
const double _kParticleMaxDistance = 180;
const double _kParticleDriftAmplitude = 6;
const double _kParticleOpacityMin = 0.3;
const double _kParticleOpacityMax = 0.9;
const double _kParticleFadeDelayMax = 0.55;

double _msToProgress(int ms) => ms / _kTotalMs;

// ---------------------------------------------------------------------------
// SplashScreen
// ---------------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _idleController;

  // Phase 1 – Ignition
  late final Animation<double> _ignitionRadius;
  late final Animation<double> _ignitionGlowOpacity;
  late final Animation<double> _ignitionGlowBlur;
  late final Animation<double> _ignitionGlowSpread;

  // Phase 2 – Circular Reveal
  late final Animation<double> _circularRevealProgress;

  // Phase 3 – Logo Reveal
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;

  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  bool _completed = false;

  // ---------------------------------------------------------------------------
  // initState
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: _kTotalDuration,
    );

    _idleController = AnimationController(
      vsync: this,
      duration: _kIdleDuration,
    );

    const ignitionCurve = Curves.easeIn;
    final ignitionInterval = Interval(
      0,
      _msToProgress(_kIgnitionEndMs),
      curve: ignitionCurve,
    );

    _ignitionRadius = Tween<double>(
      begin: 0,
      end: _kIgnitionMaxRadius,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: ignitionInterval,
    ));

    _ignitionGlowOpacity = Tween<double>(
      begin: 0,
      end: _kIgnitionGlowOpacityMax,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: ignitionInterval,
    ));

    _ignitionGlowBlur = Tween<double>(
      begin: 0,
      end: _kIgnitionGlowBlurMax,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: ignitionInterval,
    ));

    _ignitionGlowSpread = Tween<double>(
      begin: 0,
      end: _kIgnitionGlowSpreadMax,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: ignitionInterval,
    ));

    // Phase 2 – Circular Reveal (500ms → 1100ms)
    _circularRevealProgress = CurvedAnimation(
      parent: _mainController,
      curve: Interval(
        _msToProgress(_kIgnitionEndMs),
        _msToProgress(_kCircularRevealEndMs),
        curve: Curves.easeInOutCubic,
      ),
    );

    // Phase 3 – Logo Reveal (1100ms → 1900ms)
    final logoInterval = Interval(
      _msToProgress(_kCircularRevealEndMs),
      1,
      curve: Curves.easeOutBack,
    );

    _logoOpacity = CurvedAnimation(
      parent: _mainController,
      curve: Interval(
        _msToProgress(_kCircularRevealEndMs),
        1,
        curve: Curves.easeOut,
      ),
    );

    _logoScale = Tween<double>(
      begin: _kLogoScaleBegin,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: logoInterval,
    ));

    _particles.addAll(_createParticles());

    _mainController.forward();

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _idleController.repeat();
        _notifyComplete();

        // TODO: Navigator.pushReplacement to Home Screen
      }
    });
  }

  void _notifyComplete() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxRevealRadius = _maxRevealRadius(size);

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _idleController]),
        builder: (context, child) {
          final revealRadius = _currentRevealRadius(maxRevealRadius);
          final showIgnition =
              _mainController.value <= _msToProgress(_kIgnitionEndMs);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Black backdrop outside the reveal circle.
              const ColoredBox(color: Colors.black),

              // Phase 2 – brand color revealed through expanding circle.
              ClipPath(
                clipper: CircularRevealClipper(radius: revealRadius),
                child: const ColoredBox(color: _kPrimaryColor),
              ),

              // Phase 1 – pulsing ignition dot with independent glow channels.
              if (showIgnition) _buildIgnitionDot(),

              // Phase 3 + Idle – ambient particles (drift + twinkle).
              CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  revealProgress: _mainController.value,
                  idleProgress: _idleController.value,
                ),
              ),

              // Phase 3 – logo reveal; stays static once animation completes.
              Center(child: child!),
            ],
          );
        },
        child: FadeTransition(
          opacity: _logoOpacity,
          child: ScaleTransition(
            scale: _logoScale,
            child: _buildLogo(),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper Methods
  // ---------------------------------------------------------------------------

  List<Particle> _createParticles() {
    return List.generate(_kParticleCount, (_) {
      return Particle(
        angle: _random.nextDouble() * math.pi * 2,
        distance: _random.nextDouble() * _kParticleMaxDistance,
        radius: 1.5 + _random.nextDouble() * 2.5,
        delay: _random.nextDouble() * _kParticleFadeDelayMax,
        phase: _random.nextDouble() * math.pi * 2,
        speed: 2 + _random.nextDouble() * 2,
      );
    });
  }

  double _maxRevealRadius(Size size) {
    return math.sqrt(size.width * size.width + size.height * size.height);
  }

  double _currentRevealRadius(double maxRadius) {
    return _kIgnitionMaxRadius +
        (maxRadius - _kIgnitionMaxRadius) * _circularRevealProgress.value;
  }

  Widget _buildIgnitionDot() {
    final glowOpacity = _ignitionGlowOpacity.value;
    final radius = _ignitionRadius.value;

    return Center(
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          color: _kPrimaryColor.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _kPrimaryColor.withValues(alpha: glowOpacity),
              blurRadius: _ignitionGlowBlur.value,
              spreadRadius: _ignitionGlowSpread.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.shopping_bag,
          color: _kSecondaryColor,
          size: _kLogoIconSize,
        ),
        SizedBox(height: _kLogoSpacing),
        Text(
          'Bazaar Suez',
          style: TextStyle(
            color: _kSecondaryColor,
            fontWeight: FontWeight.bold,
            fontSize: _kLogoFontSize,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CircularRevealClipper
// ---------------------------------------------------------------------------

class CircularRevealClipper extends CustomClipper<Path> {
  const CircularRevealClipper({required this.radius});

  final double radius;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant CircularRevealClipper oldClipper) {
    return oldClipper.radius != radius;
  }
}

// ---------------------------------------------------------------------------
// Particle Model
// ---------------------------------------------------------------------------

class Particle {
  const Particle({
    required this.angle,
    required this.distance,
    required this.radius,
    required this.delay,
    required this.phase,
    required this.speed,
  });

  final double angle;
  final double distance;
  final double radius;
  final double delay;
  final double phase;
  final double speed;

  Offset position(Size size, double idleProgress) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseX = center.dx + math.cos(angle) * distance;
    final baseY = center.dy + math.sin(angle) * distance;

    // Phase 4 – Idle Ambient: gentle two-axis drift, no jitter.
    final wave = idleProgress * math.pi * 2 * (3 / speed) + phase;
    final driftX = math.sin(wave) * _kParticleDriftAmplitude;
    final driftY = math.cos(wave * 0.73 + phase) * _kParticleDriftAmplitude;

    return Offset(baseX + driftX, baseY + driftY);
  }

  double opacity(double revealProgress, double idleProgress) {
    const logoStart = _kCircularRevealEndMs / _kTotalMs;

    // Staggered fade-in per particle during logo reveal.
    final localProgress =
        ((revealProgress - logoStart) / (1 - logoStart)).clamp(0.0, 1.0);
    final fadeIn =
        ((localProgress - delay) / (1 - delay)).clamp(0.0, 1.0);

    if (fadeIn <= 0) return 0;

    // Twinkle between 0.3 and 0.9 with unique phase/speed per particle.
    final twinkleWave =
        math.sin(idleProgress * math.pi * 2 * (3 / speed) + phase);
    final twinkle = (twinkleWave + 1) / 2;
    final ambient = _kParticleOpacityMin +
        twinkle * (_kParticleOpacityMax - _kParticleOpacityMin);

    return fadeIn * ambient;
  }
}

// ---------------------------------------------------------------------------
// ParticlePainter
// ---------------------------------------------------------------------------

class ParticlePainter extends CustomPainter {
  const ParticlePainter({
    required this.particles,
    required this.revealProgress,
    required this.idleProgress,
  });

  final List<Particle> particles;
  final double revealProgress;
  final double idleProgress;

  static const double _logoStartProgress =
      _kCircularRevealEndMs / _kTotalMs;

  @override
  void paint(Canvas canvas, Size size) {
    if (revealProgress < _logoStartProgress) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = _kSecondaryColor;

    for (final particle in particles) {
      final opacity = particle.opacity(revealProgress, idleProgress);
      if (opacity <= 0.001) continue;

      paint.color = _kSecondaryColor.withValues(alpha: opacity);
      canvas.drawCircle(
        particle.position(size, idleProgress),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.revealProgress != revealProgress ||
        oldDelegate.idleProgress != idleProgress;
  }
}
