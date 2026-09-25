import 'dart:math';
import 'package:flame/components.dart';
import '../components/player.dart';
import '../components/platform.dart';
import '../components/bullet.dart';

/// Handles physical collision resolution between players, platforms, and bullets.
class CollisionSystem {
  /// Update player physics and resolve collisions with platforms.
  static void updatePlayerPhysics({
    required PlayerComponent player,
    required List<PlatformComponent> platforms,
    required double arenaWidth,
    required double arenaHeight,
    required double dt,
  }) {
    if (player.isDead) return;

    // Apply gravity
    player.velocity.y += PlayerComponent.gravity * dt;
    if (player.velocity.y > PlayerComponent.maxFallSpeed) {
      player.velocity.y = PlayerComponent.maxFallSpeed;
    }

    // 1. Horizontal Movement & Collision
    final oldX = player.position.x;
    final targetX = player.position.x + player.velocity.x * dt;
    player.position.x = targetX;

    final halfW = PlayerComponent.playerWidth / 2;
    for (final platform in platforms) {
      final pRect = platform.rect;
      final playerRect = player.collisionRect;

      if (playerRect.overlaps(pRect)) {
        if (player.velocity.x > 0) {
          // Collided with left edge of platform/wall
          player.position.x = min(oldX, pRect.left - halfW - 0.1);
          player.velocity.x = 0;
        } else if (player.velocity.x < 0) {
          // Collided with right edge of platform/wall
          player.position.x = max(oldX, pRect.right + halfW + 0.1);
          player.velocity.x = 0;
        }
      }
    }

    // Arena horizontal clamp
    if (player.position.x < halfW + 40) {
      player.position.x = halfW + 40;
      player.velocity.x = 0;
    } else if (player.position.x > arenaWidth - halfW - 40) {
      player.position.x = arenaWidth - halfW - 40;
      player.velocity.x = 0;
    }

    // 2. Vertical Movement & Collision
    final oldY = player.position.y;
    final targetY = player.position.y + player.velocity.y * dt;
    player.position.y = targetY;
    player.isGrounded = false;

    for (final platform in platforms) {
      final pRect = platform.rect;
      final playerRect = player.collisionRect;

      if (playerRect.overlaps(pRect)) {
        if (player.velocity.y > 0) {
          // Falling down onto a platform
          // If feet were at or above the platform before this step
          if (oldY <= pRect.top + 16.0) {
            player.position.y = pRect.top;
            player.velocity.y = 0;
            player.isGrounded = true;
          }
        } else if (player.velocity.y < 0) {
          // Jumping up hitting bottom of platform/ceiling
          if (oldY - PlayerComponent.playerHeight >= pRect.bottom - 16.0) {
            player.position.y = pRect.bottom + PlayerComponent.playerHeight;
            player.velocity.y = 0;
          }
        }
      }
    }

    // 3. Abyss Fall Death: if player falls below bottom platforms into a gap
    if (player.position.y >= 1100.0) {
      player.takeDamage(
        player.maxHealth,
        attackerId: 'abyss',
        attackerName: 'The Abyss',
        weapon: 'Fall',
      );
    }
  }

  /// Check bullet collisions with platforms. Returns true if bullet hit a solid obstacle.
  static bool checkBulletPlatformCollision(
    BulletComponent bullet,
    List<PlatformComponent> platforms,
  ) {
    final bulletPoint = bullet.position.toOffset();
    for (final platform in platforms) {
      if (platform.rect.contains(bulletPoint)) {
        return true;
      }
    }
    return false;
  }

  /// Check bullet collisions with players.
  /// Returns the hit player, if any (excluding the shooter).
  static PlayerComponent? checkBulletPlayerCollision(
    BulletComponent bullet,
    Iterable<PlayerComponent> players,
  ) {
    final bulletPoint = bullet.position.toOffset();
    for (final player in players) {
      if (player.isDead) continue;
      if (player.playerId == bullet.shooterId) continue;

      if (player.collisionRect.contains(bulletPoint)) {
        return player;
      }
    }
    return null;
  }
}
