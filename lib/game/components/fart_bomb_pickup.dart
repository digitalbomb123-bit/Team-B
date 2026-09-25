import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../mini_militia_game.dart';
import 'floating_text.dart';
import 'player.dart';

/// Interactive map pickup for the Fart Bomb.
/// Spawns randomly on arena platforms, bobs in the air with glowing toxic aura,
/// and awards a fart bomb charge when collected by a player.
class FartBombPickupComponent extends PositionComponent with HasGameReference<MiniMilitiaGame> {
  final VoidCallback? onCollected;
  double _time = 0.0;
  bool _collected = false;
  final double _baseY;

  FartBombPickupComponent({
    required Vector2 position,
    this.onCollected,
  })  : _baseY = position.y,
        super(
          position: position.clone(),
          size: Vector2(36, 44),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;

    _time += dt;

    // Smooth bobbing motion
    position.y = _baseY + sin(_time * 3.5) * 6.0;

    // Check collision with local player
    final player = game.localPlayer;
    if (!player.isDead) {
      final dist = position.distanceTo(player.position - Vector2(0, 20));
      if (dist < 38.0) {
        _collect(player);
      }
    }
  }

  bool get isCollected => _collected;

  void collect(PlayerComponent player) => _collect(player);

  void _collect(PlayerComponent player) {
    if (_collected) return;
    _collected = true;

    player.fartBombCount++;
    game.notifyFartBombCountChanged(player.fartBombCount);

    // Floating pickup confirmation text
    game.world.add(
      FloatingCombatTextComponent(
        position: Vector2(position.x, position.y - 30),
        text: '+1 FART BOMB! 💨',
        color: const Color(0xFF84CC16),
        fontSize: 13,
      ),
    );

    onCollected?.call();
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = size / 2;
    final pulse = 1.0 + sin(_time * 5.0) * 0.15;

    // 1. Toxic green glowing aura
    final glowPaint = Paint()
      ..color = const Color(0xFF84CC16).withValues(alpha: 0.35 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(center.x, center.y), 18 * pulse, glowPaint);

    // 2. Canister Metallic Cap & Base (Dark Gunmetal)
    final metalPaint = Paint()..color = const Color(0xFF334155);
    final rimPaint = Paint()..color = const Color(0xFF64748B);

    // Top cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.x, center.y - 12), width: 18, height: 7),
        const Radius.circular(3),
      ),
      metalPaint,
    );
    // Canister valve
    canvas.drawCircle(Offset(center.x, center.y - 16), 3, rimPaint);

    // 3. Glass Canister with Glowing Neon Green Liquid / Gas
    final glassRect = Rect.fromCenter(center: Offset(center.x, center.y), width: 22, height: 22);
    final liquidPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFBEF264), Color(0xFF65A30D)],
      ).createShader(glassRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(glassRect, const Radius.circular(5)),
      liquidPaint,
    );

    // Glass reflection highlight
    final glassHighlight = Paint()..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.x - 8, center.y - 9, 3, 18),
        const Radius.circular(1.5),
      ),
      glassHighlight,
    );

    // Hazard Stripes / Biohazard band
    final bandPaint = Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.7);
    canvas.drawRect(Rect.fromLTWH(center.x - 11, center.y - 3, 22, 6), bandPaint);

    // Biohazard / Fart icon (💨)
    final textSpan = TextSpan(
      text: '💨',
      style: TextStyle(
        fontSize: 11,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 2,
          ),
        ],
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.x - tp.width / 2, center.y - tp.height / 2));

    // Bottom Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.x, center.y + 12), width: 18, height: 6),
        const Radius.circular(3),
      ),
      metalPaint,
    );
  }
}
