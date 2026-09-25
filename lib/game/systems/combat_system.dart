import 'package:flame/components.dart';
import '../components/player.dart';
import '../components/bullet.dart';
import '../components/platform.dart';
import 'collision_system.dart';
import '../../multiplayer/multiplayer_client.dart';
import '../../multiplayer/player_state.dart';

/// Manages bullet dispatch, damage calculations, and combat events.
class CombatSystem {
  final Component gameWorld;
  final MultiplayerClient multiplayerClient;
  final List<BulletComponent> activeBullets = [];

  CombatSystem({
    required this.gameWorld,
    required this.multiplayerClient,
  });

  /// Spawn bullet locally and broadcast network event
  void fireWeapon({
    required PlayerComponent shooter,
    required Vector2 muzzlePos,
    required double angle,
  }) {
    final shotData = shooter.weapon.fire(
      muzzlePosition: muzzlePos,
      baseAngle: angle,
      shooterId: shooter.playerId,
    );

    if (shotData == null) return;

    shooter.muzzleFlashTimer = 0.08;

    final bulletId = 'b_${DateTime.now().microsecondsSinceEpoch}_${shooter.playerId}';
    final bullet = BulletComponent(
      bulletId: bulletId,
      shooterId: shooter.playerId,
      weaponName: shotData.weaponName,
      position: shotData.muzzlePosition,
      angle: shotData.angle,
      speed: shotData.speed,
      damage: shotData.damage,
      lifetime: shotData.lifetime,
    );

    activeBullets.add(bullet);
    gameWorld.add(bullet);

    // Broadcast across network
    multiplayerClient.sendShootEvent(
      BulletNetworkEvent(
        bulletId: bulletId,
        shooterId: shooter.playerId,
        startX: shotData.muzzlePosition.x,
        startY: shotData.muzzlePosition.y,
        angle: shotData.angle,
        speed: shotData.speed,
        damage: shotData.damage,
      ),
    );
  }

  /// Spawn a bullet received from the network
  void spawnNetworkBullet(BulletNetworkEvent event) {
    // Avoid double spawning local player's own bullets
    if (event.shooterId == multiplayerClient.localPlayerId) return;

    final bullet = BulletComponent(
      bulletId: event.bulletId,
      shooterId: event.shooterId,
      position: Vector2(event.startX, event.startY),
      angle: event.angle,
      speed: event.speed,
      damage: event.damage,
    );

    activeBullets.add(bullet);
    gameWorld.add(bullet);
  }

  /// Update bullets, resolve hits and remove expired ones
  void update({
    required Iterable<PlayerComponent> players,
    required List<PlatformComponent> platforms,
  }) {
    activeBullets.removeWhere((bullet) {
      if (bullet.isExpired || bullet.parent == null) return true;

      // 1. Check platform collision
      if (CollisionSystem.checkBulletPlatformCollision(bullet, platforms)) {
        bullet.expire();
        return true;
      }

      // 2. Check player hit
      final hitPlayer = CollisionSystem.checkBulletPlayerCollision(bullet, players);
      if (hitPlayer != null) {
        hitPlayer.takeDamage(
          bullet.damage,
          attackerId: bullet.shooterId,
          weapon: bullet.weaponName,
        );

        // Report damage over network
        multiplayerClient.sendDamageEvent(
          targetPlayerId: hitPlayer.playerId,
          damage: bullet.damage,
          attackerId: bullet.shooterId,
        );

        bullet.expire();
        return true;
      }

      return false;
    });
  }

  void clear() {
    for (final b in activeBullets) {
      b.expire();
    }
    activeBullets.clear();
  }
}
