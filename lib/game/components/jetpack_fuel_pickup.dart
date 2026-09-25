import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../mini_militia_game.dart';
import 'floating_text.dart';
import 'player.dart';

/// Interactive map pickup for Additional Jetpack Fuel.
/// Spawns randomly on arena platforms, bobs in the air with glowing rocket plasma aura,
/// and awards 10 seconds of super-boost jetpack flight when collected.
class JetpackFuelPickupComponent extends PositionComponent
    with HasGameReference<MiniMilitiaGame> {
  final VoidCallback? onCollected;
  double _time = 0.0;
  bool _collected = false;
  final double _baseY;

  JetpackFuelPickupComponent({
    required Vector2 position,
    this.onCollected,
  })  : _baseY = position.y,
        super(
          position: position.clone(),
          size: Vector2(36, 44),
          anchor: Anchor.center,
        );

  bool get isCollected => _collected;

  void collect(PlayerComponent player) => _collect(player);

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;

    _time += dt;

    // Smooth floating bobbing motion
    position.y = _baseY + sin(_time * 4.0) * 6.0;

    // Check collision with local player
    final player = game.localPlayer;
    if (!player.isDead) {
      final dist = position.distanceTo(player.position - Vector2(0, 20));
      if (dist < 38.0) {
        _collect(player);
      }
    }
  }

  void _collect(PlayerComponent player) {
    if (_collected) return;
    _collected = true;

    // Award 10 seconds of super fuel
    player.applySuperFuel(10.0);

    // Floating pickup confirmation text
    if (isMounted) {
      game.world.add(
        FloatingCombatTextComponent(
          position: Vector2(position.x, position.y - 30),
          text: '+10s SUPER FUEL! 🚀',
          color: const Color(0xFF38BDF8),
          fontSize: 13,
        ),
      );
    }

    onCollected?.call();
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = size / 2;
    final pulse = 1.0 + sin(_time * 6.0) * 0.18;

    // 1. Plasma rocket glow aura
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.40 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(center.x, center.y), 20 * pulse, glowPaint);

    // 2. High-Tech Fuel Canister Cap & Pressure Valve
    final metalPaint = Paint()..color = const Color(0xFF1E293B);
    final valvePaint = Paint()..color = const Color(0xFF38BDF8);

    // Pressure valve
    canvas.drawCircle(Offset(center.x, center.y - 15), 3, valvePaint);

    // Top Cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.x, center.y - 11),
          width: 18,
          height: 6,
        ),
        const Radius.circular(2.5),
      ),
      metalPaint,
    );

    // 3. Pressurized Super-Fuel Tank (Neon Cyan / Electric Blue Gradient)
    final tankRect = Rect.fromCenter(
      center: Offset(center.x, center.y),
      width: 22,
      height: 22,
    );
    final fuelGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(tankRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(tankRect, const Radius.circular(5)),
      fuelGradient,
    );

    // Glass reflection highlight
    final glassHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.45);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.x - 8, center.y - 9, 3, 18),
        const Radius.circular(1.5),
      ),
      glassHighlight,
    );

    // Central Energy Core / Rocket Glyph (⚡ / 🚀)
    final textSpan = TextSpan(
      text: '⚡',
      style: TextStyle(
        fontSize: 13,
        color: Colors.white,
        shadows: [
          Shadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.9),
            blurRadius: 6,
          ),
        ],
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.x - tp.width / 2, center.y - tp.height / 2),
    );

    // Bottom Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.x, center.y + 12),
          width: 18,
          height: 6,
        ),
        const Radius.circular(2.5),
      ),
      metalPaint,
    );
  }
}
