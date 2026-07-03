import 'package:flutter/material.dart';

/// ويدجت ظل احترافي ناعم (Contact Shadow) يُستخدم أسفل صور المنتجات ليعطي عمقاً واقعياً.
/// A professional soft contact shadow widget used below product images to give a realistic depth.
class InstashopGroundShadow extends StatelessWidget {
  /// عرض الظل الإجمالي
  /// Total width of the shadow.
  final double width;

  /// لون الظل (افتراضياً أسود)
  /// Tint color of the shadow (defaults to black).
  final Color tint;

  /// قوة الظل وشفافيته (من 0.0 إلى 1.0)
  /// Intensity and opacity of the shadow (0.0 to 1.0).
  final double intensity;

  const InstashopGroundShadow({
    super.key,
    required this.width,
    this.tint = Colors.black,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // نقوم بحساب الارتفاع تلقائياً بناءً على العرض للحفاظ على النسبة الجمالية للظل
    // We calculate height automatically based on width to maintain the aesthetic aspect ratio of the shadow.
    return CustomPaint(
      size: Size(width, width * 0.22),
      painter: _ContactShadowPainter(tint: tint, intensity: intensity),
    );
  }
}

/// الرسام الخاص برسم الظل الواقعي باستخدام التدرج الشعاعي ونواة مركزية.
/// Custom painter to draw the realistic shadow using radial gradient and a core oval.
class _ContactShadowPainter extends CustomPainter {
  final Color tint;
  final double intensity;

  _ContactShadowPainter({required this.tint, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    // حساب المركز والأبعاد البيضاوية للظل
    // Calculating center and oval dimensions of the shadow.
    final center = Offset(size.width / 2, size.height * 0.5);
    final ovalW = size.width * 0.9;
    final ovalH = size.height * 0.55;

    final rect = Rect.fromCenter(center: center, width: ovalW, height: ovalH);

    // استخدام withValues للتوافق مع أحدث إصدار من Flutter
    // Using withValues to support the latest Flutter API guidelines (replaces withOpacity).
    final gradient = RadialGradient(
      colors: [
        tint.withValues(alpha: 0.22 * intensity),
        tint.withValues(alpha: 0.10 * intensity),
        tint.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.55, 1.0],
    );

    // إعداد أداة الرسم للظل الخارجي الناعم
    // Setting up paint for the soft outer shadow.
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, ovalH / ovalW);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, ovalW / 2, paint);
    canvas.restore();

    // رسم النواة المركزية للظل التي تعطي إحساس نقطة التلامس بين المنتج والسطح
    // Drawing the core center shadow to simulate the touchpoint of the product.
    final corePaint = Paint()
      ..color = tint.withValues(alpha: 0.20 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: ovalW * 0.4,
        height: ovalH * 0.4,
      ),
      corePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ContactShadowPainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.intensity != intensity;
}
