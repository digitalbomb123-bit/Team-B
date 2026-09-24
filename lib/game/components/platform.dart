import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum PlatformType {
  ground,
  floating,
  wall,
  barrier,
}

/// Solid platform component for arena terrain and obstacles.
class PlatformComponent extends PositionComponent {
  final PlatformType platformType;
  final Color baseColor;
  final Color accentColor;

  PlatformComponent({
    required Vector2 position,
    required Vector2 size,
    this.platformType = PlatformType.floating,
    Color? baseColor,
    Color? accentColor,
  })  : baseColor = baseColor ?? const Color(0xFF1E293B),
        accentColor = accentColor ?? const Color(0xFF38BDF8),
        super(position: position, size: size, anchor: Anchor.topLeft);

  Rect get rect => toRect();

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(4),
    );

    // Platform Body Fill
    final paintBody = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paintBody);

    // Platform Border
    final paintBorder = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rrect, paintBorder);

    // Platform Top High-Tech Edge Line
    final paintHighlight = Paint()
      ..color = accentColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(2, 2), Offset(width - 2, 2), paintHighlight);

    // Subtle Grid / Rivet Texture
    final paintRivets = Paint()..color = Colors.white.withValues(alpha: 0.15);
    for (double x = 16; x < width - 8; x += 32) {
      canvas.drawCircle(Offset(x, 8), 2, paintRivets);
      if (height > 24) {
        canvas.drawCircle(Offset(x, height - 8), 2, paintRivets);
      }
    }
  }
}
