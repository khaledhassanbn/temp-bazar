import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

/// Matches Shape Layer 1 fill in bazaar.json: [0.1176, 0.5961, 0.8353]
const Color splashBackground = Color(0xFF1E98D5);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completed = false;

  static const _splashOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(_splashOverlayStyle);
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _notifyComplete();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _splashOverlayStyle,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: splashBackground,
          child: SizedBox.expand(
            child: Lottie.asset(
              'assets/animations/bazaar.json',
              controller: _controller,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              onLoaded: (composition) {
                _controller
                  ..duration = composition.duration
                  ..forward();
              },
            ),
          ),
        ),
      ),
    );
  }
}
