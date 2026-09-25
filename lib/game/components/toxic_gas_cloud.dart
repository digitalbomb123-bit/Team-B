import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../mini_militia_game.dart';
import 'floating_text.dart';
import 'player.dart';

/// A lingering toxic green gas cloud created by a fart bomb blast.
/// Deals gradual damage over time to any player caught inside its noxious fumes.
class ToxicGasCloudComponent extends PositionComponent with HasGameReference<MiniMilitiaGame> {
  final String shooterId;
  final double maxRadius;
  final double lifetime;

  double _age = 0.0;
  double _damageTickTimer = 0.0;
  static const double damageTickInterval = 0.25;
  static const double damagePerTick = 4.5; // ~18 DPS

  // Pre-generated cloud puff offsets for organic undulating smoke
  final List<Offset> _puffOffsets = [
    const Offset(0, 0),
    const Offset(-22, -10),
    const Offset(20, -12),
    const Offset(-14, 18),
    const Offset(18, 16),
    const Offset(-28, 4),
    const Offset(26, -2),
    const Offset(0, -26),
    const Offset(0, 24),
  ];

  // Particle bubbles within the gas
  final List<_GasBubble> _bubbles = [];
  final Random _rnd = Random();

  ToxicGasCloudComponent({
    required Vector2 position,
    required this.shooterId,
    this.maxRadius = 85.0,
    this.lifetime = 7.0,
  }) : super(position: position.clone(), anchor: Anchor.center) {
    size = Vector2.all(maxRadius * 2);
    // Initialize bubbles
    for (int i = 0; i < 14; i++) {
      _bubbles.add(
        _GasBubble(
          relX: (_rnd.nextDouble() - 0.5) * maxRadius * 1.2,
          relY: (_rnd.nextDouble() - 0.5) * maxRadius * 1.2,
          speed: 12.0 + _rnd.nextDouble() * 24.0,
          radius: 2.0 + _rnd.nextDouble() * 4.0,
        ),
      );
    }
  }

  double get currentRadius {
    if (_age < 1.2) {
      // Rapid billow expansion
      return (20.0 + (maxRadius - 20.0) * (_age / 1.2));
    }
    return maxRadius;
  }

  double get currentOpacity {
    if (_age < 0.4) {
      return (_age / 0.4).clamp(0.0, 1.0);
    }
    if (_age > lifetime - 1.5) {
      return ((lifetime - _age) / 1.5).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;

    if (_age >= lifetime) {
      removeFromParent();
      return;
    }

    // Update internal gas bubbles
    for (final b in _bubbles) {
      b.relY -= b.speed * dt;
      b.relX += sin(_age * 3.0 + b.speed) * 8.0 * dt;
      if (b.relY < -currentRadius) {
        b.relY = currentRadius * 0.8;
        b.relX = (_rnd.nextDouble() - 0.5) * currentRadius;
      }
    }

    // Damage over time tick
    _damageTickTimer += dt;
    if (_damageTickTimer >= damageTickInterval) {
      _damageTickTimer = 0.0;
      _applyGasDamage();
    }
  }

  void _applyGasDamage() {
    final radius = currentRadius;
    final allPlayers = <PlayerComponent>[];
    try {
      allPlayers.add(game.localPlayer);
    } catch (_) {}
    allPlayers.addAll(game.remotePlayers.values);
    for (final child in game.world.children.whereType<PlayerComponent>()) {
      if (!allPlayers.contains(child)) {
        allPlayers.add(child);
      }
    }

    for (final player in allPlayers) {
      if (player.isDead) continue;

      // Distance from cloud center to player position
      final dist = position.distanceTo(player.position);
      if (dist <= radius + 18.0) {
        // Player is inhaling the toxic gas!
        player.takeDamage(
          damagePerTick,
          attackerId: shooterId,
          weapon: 'fart_bomb',
        );
        player.poisonFlashTimer = 0.35;

        // Broadcast damage event so kill tracking and multiplayer stay consistent
        game.multiplayerClient.sendDamageEvent(
          targetPlayerId: player.playerId,
          damage: damagePerTick,
          attackerId: shooterId,
        );

        // Show floating green poison text occasionally
        if (_rnd.nextDouble() < 0.25) {
          game.world.add(
            FloatingCombatTextComponent(
              position: Vector2(player.position.x, player.position.y - 40),
              text: '-${damagePerTick.round()} ☣️',
              color: const Color(0xFF84CC16),
              fontSize: 11,
            ),
          );
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final opacity = currentOpacity;
    if (opacity <= 0.01) return;

    final radius = currentRadius;
    final center = size / 2;

    // 1. Soft glowing outer haze
    final hazePaint = Paint()
      ..color = const Color(0xFF84CC16).withValues(alpha: opacity * 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(center.x, center.y), radius, hazePaint);

    // 2. Rolling organic toxic cloud lobes
    final lobePaint1 = Paint()
      ..color = const Color(0xFF65A30D).withValues(alpha: opacity * 0.40);
    final lobePaint2 = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: opacity * 0.35);
    final corePaint = Paint()
      ..color = const Color(0xFF15803D).withValues(alpha: opacity * 0.50);

    for (int i = 0; i < _puffOffsets.length; i++) {
      final baseOffset = _puffOffsets[i];
      final wobbleX = sin(_age * 2.5 + i) * 6.0;
      final wobbleY = cos(_age * 2.0 + i) * 5.0;
      final scaleFactor = (radius / maxRadius);
      final puffX = center.x + (baseOffset.dx + wobbleX) * scaleFactor;
      final puffY = center.y + (baseOffset.dy + wobbleY) * scaleFactor;
      final puffRadius = (radius * 0.45) + sin(_age * 3.0 + i) * 4.0;

      final paint = (i % 2 == 0) ? lobePaint1 : lobePaint2;
      canvas.drawCircle(Offset(puffX, puffY), max(8.0, puffRadius), paint);
    }

    // 3. Dense noxious core
    canvas.drawCircle(
      Offset(center.x, center.y),
      radius * 0.45,
      corePaint,
    );

    // 4. Toxic bubbles floating up
    final bubblePaint = Paint()
      ..color = const Color(0xFFBEF264).withValues(alpha: opacity * 0.75)
      ..style = PaintingStyle.fill;

    for (final b in _bubbles) {
      if (b.relX.abs() <= radius && b.relY.abs() <= radius) {
        canvas.drawCircle(
          Offset(center.x + b.relX, center.y + b.relY),
          b.radius,
          bubblePaint,
        );
      }
    }
  }
}

class _GasBubble {
  double relX;
  double relY;
  final double speed;
  final double radius;

  _GasBubble({
    required this.relX,
    required this.relY,
    required this.speed,
    required this.radius,
  });
}
