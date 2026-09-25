import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../mini_militia_game.dart';
import 'floating_text.dart';
import 'player.dart';

/// Tactical Poop Trap laid exclusively by the Jos avatar.
/// Lingers on the ground; when an enemy steps on it, they become stuck and immobilized!
class PoopTrapComponent extends PositionComponent with HasGameReference<MiniMilitiaGame> {
  final String ownerId;
  final String ownerName;
  final double stuckDuration;

  double lifetime = 35.0;
  bool isSettled = false;
  bool isTriggered = false;
  double squishTimer = 0.0;
  double _verticalVelocity = 0.0;
  double _steamTime = 0.0;

  // Visual styling paints
  final Paint _basePuddlePaint = Paint()
    ..color = const Color(0xFF451A03).withValues(alpha: 0.70)
    ..style = PaintingStyle.fill;

  final Paint _coilPaintDark = Paint()
    ..color = const Color(0xFF78350F)
    ..style = PaintingStyle.fill;

  final Paint _coilPaintMid = Paint()
    ..color = const Color(0xFF92400E)
    ..style = PaintingStyle.fill;

  final Paint _coilPaintLight = Paint()
    ..color = const Color(0xFFB45309)
    ..style = PaintingStyle.fill;

  final Paint _highlightPaint = Paint()
    ..color = const Color(0xFFFCD34D).withValues(alpha: 0.50)
    ..style = PaintingStyle.fill;

  final Paint _steamPaint = Paint()
    ..color = const Color(0xFFCA8A04).withValues(alpha: 0.55)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  PoopTrapComponent({
    required Vector2 position,
    required this.ownerId,
    this.ownerName = 'Jos',
    this.stuckDuration = 3.5,
  }) : super(
          position: position,
          size: Vector2(30, 26),
          anchor: Anchor.bottomCenter,
        );

  Rect get trapRect => Rect.fromLTWH(
        position.x - size.x / 2,
        position.y - size.y,
        size.x,
        size.y,
      );

  @override
  void update(double dt) {
    super.update(dt);
    _steamTime += dt;

    if (isTriggered) {
      squishTimer -= dt;
      if (squishTimer <= 0) {
        removeFromParent();
      }
      return;
    }

    lifetime -= dt;
    if (lifetime <= 0) {
      removeFromParent();
      return;
    }

    // 1. Gravity physics until landing on a solid platform/ground
    if (!isSettled) {
      _verticalVelocity += 650.0 * dt;
      final targetY = position.y + _verticalVelocity * dt;

      // Check arena platforms
      bool hitGround = false;
      try {
        for (final platform in game.arena.platforms) {
          final pRect = platform.rect;
          // Check if bottom lands on top of platform
          if (position.x >= pRect.left &&
              position.x <= pRect.right &&
              position.y <= pRect.top + 8 &&
              targetY >= pRect.top) {
            position.y = pRect.top;
            _verticalVelocity = 0;
            isSettled = true;
            hitGround = true;
            break;
          }
        }
      } catch (_) {}

      if (!hitGround) {
        position.y = targetY;
        // Arena bottom clamp safety
        if (position.y >= 1000.0) {
          position.y = 1000.0;
          _verticalVelocity = 0;
          isSettled = true;
        }
      }
    }

    // 2. Collision detection with enemies
    _checkEnemyCollision();
  }

  void _checkEnemyCollision() {
    if (isTriggered) return;

    final allPlayers = <PlayerComponent>[];
    try {
      allPlayers.add(game.localPlayer);
    } catch (_) {}
    try {
      allPlayers.addAll(game.remotePlayers.values);
    } catch (_) {}
    try {
      for (final child in game.world.children.whereType<PlayerComponent>()) {
        if (!allPlayers.contains(child)) {
          allPlayers.add(child);
        }
      }
    } catch (_) {}

    final rect = trapRect;

    for (final player in allPlayers) {
      if (player.isDead) continue;
      // Jos cannot get stuck in his own poop!
      if (player.playerId == ownerId) continue;
      // If already stuck, continue
      if (player.isStuck) continue;

      if (player.collisionRect.overlaps(rect)) {
        // ENEMY TRAPPED IN POOP!
        isTriggered = true;
        squishTimer = 0.6;
        player.applyPoopStuck(stuckDuration, trapperName: ownerName);

        // Show comic floating alert above trapped enemy
        try {
          game.world.add(
            FloatingCombatTextComponent(
              position: Vector2(player.position.x, player.position.y - 65),
              text: '💩 STUCK IN POOP!',
              color: const Color(0xFFFBBF24),
              fontSize: 13,
            ),
          );
        } catch (_) {}

        break;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    // Center origin horizontally at bottom
    canvas.translate(size.x / 2, size.y);

    if (isTriggered) {
      // Squashed flat animation
      final squishProgress = (squishTimer / 0.6).clamp(0.0, 1.0);
      canvas.scale(1.0 + (1.0 - squishProgress) * 0.45, squishProgress.clamp(0.2, 1.0));
    }

    // 1. Base sticky puddle
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -1), width: size.x * 1.05, height: 7),
      _basePuddlePaint,
    );

    // 2. Bottom Tier Coil
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -5), width: size.x * 0.88, height: 10),
      _coilPaintDark,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-2, -6), width: size.x * 0.72, height: 7),
      _coilPaintMid,
    );

    // 3. Middle Tier Coil
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -11), width: size.x * 0.68, height: 9),
      _coilPaintDark,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-1, -12), width: size.x * 0.54, height: 6.5),
      _coilPaintLight,
    );

    // 4. Top Swirl Tip
    final topSwirl = Path()
      ..moveTo(-size.x * 0.22, -15)
      ..quadraticBezierTo(-size.x * 0.15, -23, 2, -24)
      ..quadraticBezierTo(size.x * 0.24, -20, size.x * 0.18, -15)
      ..close();
    canvas.drawPath(topSwirl, _coilPaintMid);

    // Top tip curl
    final tipCurl = Path()
      ..moveTo(0, -22)
      ..quadraticBezierTo(4, -27, 7, -23)
      ..quadraticBezierTo(3, -21, 0, -22);
    canvas.drawPath(tipCurl, _coilPaintLight);

    // 5. Glossy shine highlights
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-5, -7), width: 5, height: 2.2),
      _highlightPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-3, -13), width: 4, height: 2),
      _highlightPaint,
    );

    // 6. Cartoon Stink Waves (Wavy rising yellow steam)
    if (!isTriggered) {
      final steamWave1 = sin(_steamTime * 5.0) * 2.5;
      final steamWave2 = cos(_steamTime * 4.5) * 2.5;

      final p1 = Path()
        ..moveTo(-6, -26)
        ..quadraticBezierTo(-6 + steamWave1, -33, -5, -40);
      canvas.drawPath(p1, _steamPaint);

      final p2 = Path()
        ..moveTo(4, -25)
        ..quadraticBezierTo(4 + steamWave2, -32, 5, -38);
      canvas.drawPath(p2, _steamPaint);
    }

    canvas.restore();
  }
}
