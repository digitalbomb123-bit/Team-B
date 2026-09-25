import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Floating text effect for damage, pickups, and comical fart sound effects.
class FloatingCombatTextComponent extends PositionComponent {
  final String text;
  final Color color;
  final double fontSize;
  double _lifetime = 1.1;
  final double _initialLifetime = 1.1;
  final Vector2 _velocity = Vector2(0, -38);

  FloatingCombatTextComponent({
    required Vector2 position,
    required this.text,
    this.color = Colors.white,
    this.fontSize = 13.0,
  }) : super(position: position.clone(), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    _lifetime -= dt;
    if (_lifetime <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final alpha = (_lifetime / _initialLifetime).clamp(0.0, 1.0);
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: alpha * 0.9),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );

    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}
