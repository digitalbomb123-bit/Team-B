import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'player.dart';
import '../mini_militia_game.dart';

/// Renders a dynamic red directional radar pointer around the local player
/// indicating the direction of any alive enemy within detection radius.
class EnemyRadarIndicatorComponent extends Component
    with HasGameReference<MiniMilitiaGame> {
  static const double detectionRadius = 900.0;

  final Paint _fillPaint = Paint()
    ..color = const Color(0xFFEF4444)
    ..style = PaintingStyle.fill;

  final Paint _strokePaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  final Paint _glowPaint = Paint()
    ..color = const Color(0xFFFF0000).withValues(alpha: 0.45)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  /// Checks if an enemy is within detection range and should be indicated on radar
  static bool shouldTrackEnemy(PlayerComponent localPlayer, PlayerComponent enemy) {
    if (enemy.isDead || localPlayer.isDead) return false;
    final dx = enemy.position.x - localPlayer.position.x;
    final dy = (enemy.position.y - PlayerComponent.playerHeight / 2) -
        (localPlayer.position.y - PlayerComponent.playerHeight / 2);
    final dist = sqrt(dx * dx + dy * dy);
    return dist > 65.0 && dist <= detectionRadius;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final localPlayer = game.localPlayer;
    if (localPlayer.isDead) return;

    final localPos = localPlayer.position;
    final localCenter = Offset(localPos.x, localPos.y - PlayerComponent.playerHeight / 2);

    // Keep pointer at ~68 screen pixels distance from player regardless of zoom
    final zoom = game.camera.viewfinder.zoom.clamp(0.4, 2.0);
    final orbitalDistance = 68.0 / zoom;
    final pointerLength = 14.0 / zoom;
    final pointerBase = 8.0 / zoom;

    for (final enemy in game.remotePlayers.values) {
      if (enemy.isDead) continue;

      final enemyPos = enemy.position;
      final dx = enemyPos.x - localPos.x;
      final dy = (enemyPos.y - PlayerComponent.playerHeight / 2) -
          (localPos.y - PlayerComponent.playerHeight / 2);
      final dist = sqrt(dx * dx + dy * dy);

      if (dist <= 65.0 || dist > detectionRadius) continue;

      final angle = atan2(dy, dx);
      final alphaRatio = (1.0 - (dist / detectionRadius) * 0.55).clamp(0.4, 1.0);

      // Orbital position around local player
      final ox = localCenter.dx + cos(angle) * orbitalDistance;
      final oy = localCenter.dy + sin(angle) * orbitalDistance;

      // Pointer triangle vertices
      // Tip points towards enemy
      final tipX = ox + cos(angle) * (pointerLength * 0.6);
      final tipY = oy + sin(angle) * (pointerLength * 0.6);

      // Base left and right
      final baseAngle1 = angle + pi - 0.55;
      final baseAngle2 = angle + pi + 0.55;
      final base1X = ox + cos(baseAngle1) * pointerBase;
      final base1Y = oy + sin(baseAngle1) * pointerBase;
      final base2X = ox + cos(baseAngle2) * pointerBase;
      final base2Y = oy + sin(baseAngle2) * pointerBase;

      final path = Path()
        ..moveTo(tipX, tipY)
        ..lineTo(base1X, base1Y)
        ..lineTo(ox - cos(angle) * (pointerBase * 0.3), oy - sin(angle) * (pointerBase * 0.3))
        ..lineTo(base2X, base2Y)
        ..close();

      // Apply dynamic opacity
      _fillPaint.color = const Color(0xFFEF4444).withValues(alpha: alphaRatio);
      _strokePaint.color = Colors.white.withValues(alpha: alphaRatio * 0.85);

      // Glow effect
      canvas.drawCircle(Offset(ox, oy), pointerLength * 0.7, _glowPaint);

      // Draw pointer arrow
      canvas.drawPath(path, _fillPaint);
      canvas.drawPath(path, _strokePaint);
    }
  }
}
