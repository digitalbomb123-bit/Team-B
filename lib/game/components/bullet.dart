import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Projectile fired by weapons with speed, lifetime, and damage.
class BulletComponent extends PositionComponent {
  final String bulletId;
  final String shooterId;
  final String weaponName;
  final Vector2 velocity;
  final double damage;
  final double lifetime;

  double _elapsed = 0.0;
  bool isExpired = false;

  BulletComponent({
    required this.bulletId,
    required this.shooterId,
    this.weaponName = 'bullet',
    required Vector2 position,
    required double angle,
    required double speed,
    required this.damage,
    this.lifetime = 1.6,
  })  : velocity = Vector2(cos(angle), sin(angle)) * speed,
        super(
          position: position,
          size: Vector2(14, 5),
          angle: angle,
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);

    if (isExpired) return;

    _elapsed += dt;
    if (_elapsed >= lifetime) {
      expire();
      return;
    }

    position.add(velocity * dt);
  }

  void expire() {
    isExpired = true;
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Glowing bullet tracer
    final paintGlow = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(7, 2.5), width: 18, height: 8),
      paintGlow,
    );

    // Bullet Core (Bright yellow / orange bullet)
    final paintCore = Paint()
      ..color = const Color(0xFFFFF07C)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(7, 2.5), width: 14, height: 4),
        const Radius.circular(2),
      ),
      paintCore,
    );

    // Front tip bright white
    final paintTip = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(12, 2.5), 2, paintTip);
  }
}
