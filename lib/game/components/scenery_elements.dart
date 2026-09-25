import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Natural foliage camouflage bush element.
/// Provides visual cover, organic contrast against metal/stone, and subtle ambient sway.
class BushComponent extends PositionComponent {
  final double radius;
  final int seed;
  double _time = 0.0;

  BushComponent({
    required Vector2 position,
    this.radius = 22.0,
    this.seed = 0,
  }) : super(
          position: position,
          size: Vector2(radius * 2.2, radius * 1.6),
          anchor: Anchor.bottomCenter,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final sway = sin(_time * 2.0 + seed) * 1.5;
    canvas.save();
    canvas.translate(size.x / 2 + sway, size.y);

    // Deep shadow base
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -4), width: radius * 2.2, height: radius * 0.7),
      shadowPaint,
    );

    // Dark foliage background layer
    final darkGreen = Paint()..color = const Color(0xFF14532D);
    canvas.drawCircle(Offset(-radius * 0.45, -radius * 0.7), radius * 0.65, darkGreen);
    canvas.drawCircle(Offset(radius * 0.45, -radius * 0.65), radius * 0.65, darkGreen);
    canvas.drawCircle(Offset(0, -radius * 0.9), radius * 0.7, darkGreen);

    // Mid foliage layer
    final midGreen = Paint()..color = const Color(0xFF16A34A);
    canvas.drawCircle(Offset(-radius * 0.3, -radius * 0.6), radius * 0.55, midGreen);
    canvas.drawCircle(Offset(radius * 0.35, -radius * 0.55), radius * 0.55, midGreen);
    canvas.drawCircle(Offset(0, -radius * 0.75), radius * 0.6, midGreen);

    // Bright leafy highlights
    final lightGreen = Paint()..color = const Color(0xFF4ADE80).withValues(alpha: 0.75);
    canvas.drawCircle(Offset(-radius * 0.15, -radius * 0.85), radius * 0.28, lightGreen);
    canvas.drawCircle(Offset(radius * 0.2, -radius * 0.7), radius * 0.24, lightGreen);

    canvas.restore();
  }
}

/// Natural tactical granite/slate boulder.
/// Ground obstacle with faceted stone geometry, highlights, and subtle moss.
class StoneComponent extends PositionComponent {
  final double radius;
  final int seed;

  StoneComponent({
    required Vector2 position,
    this.radius = 18.0,
    this.seed = 0,
  }) : super(
          position: position,
          size: Vector2(radius * 2.2, radius * 1.5),
          anchor: Anchor.bottomCenter,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    canvas.translate(size.x / 2, size.y);

    // Ground Contact Shadow
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.4);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -2), width: radius * 2.2, height: radius * 0.6),
      shadowPaint,
    );

    // Faceted Rock Polygon
    final path = Path()
      ..moveTo(-radius, -2)
      ..lineTo(-radius * 0.85, -radius * 0.7)
      ..lineTo(-radius * 0.3, -radius * 1.2)
      ..lineTo(radius * 0.4, -radius * 1.1)
      ..lineTo(radius * 0.95, -radius * 0.5)
      ..lineTo(radius, -2)
      ..close();

    // Dark slate rock body
    final rockPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawPath(path, rockPaint);

    // Lighter facet (Top left light source)
    final facetPath = Path()
      ..moveTo(-radius * 0.85, -radius * 0.7)
      ..lineTo(-radius * 0.3, -radius * 1.2)
      ..lineTo(0, -radius * 0.6)
      ..lineTo(-radius * 0.4, -2)
      ..close();
    final lightFacet = Paint()..color = const Color(0xFF64748B);
    canvas.drawPath(facetPath, lightFacet);

    // Highlight ridge
    final edgePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-radius * 0.3, -radius * 1.2), Offset(0, -radius * 0.6), edgePaint);

    // Subtle moss patch on top edge
    final mossPaint = Paint()..color = const Color(0xFF4D7C0F).withValues(alpha: 0.85);
    canvas.drawCircle(Offset(-radius * 0.25, -radius * 1.05), radius * 0.25, mossPaint);

    canvas.restore();
  }
}
