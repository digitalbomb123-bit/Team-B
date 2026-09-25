import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_b_shooter/game/camera/game_camera.dart';
import 'package:team_b_shooter/game/components/bullet.dart';
import 'package:team_b_shooter/game/components/gun_pickup.dart';
import 'package:team_b_shooter/game/components/enemy_radar_indicator.dart';
import 'package:team_b_shooter/game/components/platform.dart';
import 'package:team_b_shooter/game/components/player.dart';
import 'package:team_b_shooter/game/components/scenery_elements.dart';
import 'package:team_b_shooter/game/components/weapon.dart';
import 'package:team_b_shooter/game/components/wood_cabin.dart';
import 'package:team_b_shooter/game/systems/collision_system.dart';
import 'package:team_b_shooter/game/world/arena.dart';

void main() {
  group('Weapon Specification Tests', () {
    test('Uzi stats match user specifications', () {
      final uzi = Weapon.uzi();
      expect(uzi.type, WeaponType.uzi);
      expect(uzi.damage, 20.0);
      expect(uzi.zoom, 2.0);
      expect(uzi.reloadDuration, 1.5);
      expect(uzi.currentAmmo, 25);
    });

    test('AK-47 stats match user specifications', () {
      final ak47 = Weapon.ak47();
      expect(ak47.type, WeaponType.ak47);
      expect(ak47.damage, 35.0);
      expect(ak47.zoom, 2.5);
      expect(ak47.reloadDuration, 2.2);
      expect(ak47.currentAmmo, 30);
    });

    test('M4A1 stats match user specifications', () {
      final m4a1 = Weapon.m4a1();
      expect(m4a1.type, WeaponType.m4a1);
      expect(m4a1.damage, 28.0);
      expect(m4a1.zoom, 3.0);
      expect(m4a1.reloadDuration, 1.8);
      expect(m4a1.currentAmmo, 30);
    });

    test('Desert Eagle stats match user specifications', () {
      final deagle = Weapon.desertEagle();
      expect(deagle.type, WeaponType.desertEagle);
      expect(deagle.damage, 60.0);
      expect(deagle.zoom, 2.0);
      expect(deagle.reloadDuration, 2.0);
      expect(deagle.currentAmmo, 7);
    });

    test('AWP stats match user specifications', () {
      final awp = Weapon.awp();
      expect(awp.type, WeaponType.awp);
      expect(awp.damage, 100.0);
      expect(awp.zoom, 6.0);
      expect(awp.reloadDuration, 3.0);
      expect(awp.currentAmmo, 5);
    });

    test('Weapon reload mechanics work properly', () {
      final awp = Weapon.awp();
      expect(awp.canFire, isTrue);

      // Drain all rounds
      awp.currentAmmo = 0;
      expect(awp.currentAmmo, 0);

      // Trigger reload
      awp.startReload();
      expect(awp.isReloading, isTrue);
      expect(awp.canFire, isFalse);

      // Advance partial reload time
      awp.update(1.5);
      expect(awp.isReloading, isTrue);
      expect(awp.reloadProgress, closeTo(0.5, 0.05));

      // Complete reload
      awp.update(1.6);
      expect(awp.isReloading, isFalse);
      expect(awp.currentAmmo, awp.magazineCapacity);
      expect(awp.canFire, isTrue);
    });

    test('Bullet component records weaponName for kill attribution', () {
      final bullet = BulletComponent(
        bulletId: 'b-1',
        position: Vector2(100, 100),
        angle: 0.0,
        shooterId: 'player-1',
        speed: 900,
        damage: 100,
        weaponName: 'AWP',
      );
      expect(bullet.weaponName, 'AWP');
    });

    test('AWP multi-stage zoom cycles correctly through 6x, 3x, and 2x', () {
      final awp = Weapon.awp();
      expect(awp.zoom, 6.0);
      expect(awp.zoomLevels, [6.0, 3.0, 2.0]);

      // Cycle to next zoom: 3x
      awp.cycleZoom();
      expect(awp.zoom, 3.0);

      // Cycle to next zoom: 2x
      awp.cycleZoom();
      expect(awp.zoom, 2.0);

      // Cycle back to: 6x
      awp.cycleZoom();
      expect(awp.zoom, 6.0);
    });

    test('Camera zoom config maps higher weapon zoom to wider view (zoom out)', () {
      // 1.0x (normal/unzoomed)
      final zoom1x = GameCameraConfig.getCameraZoomForWeaponZoom(1.0);
      expect(zoom1x, 1.0);

      // 2.0x (Uzi / Deagle / AWP 2x)
      final zoom2x = GameCameraConfig.getCameraZoomForWeaponZoom(2.0);

      // 3.0x (M4A1 / AWP 3x)
      final zoom3x = GameCameraConfig.getCameraZoomForWeaponZoom(3.0);

      // 6.0x (AWP 6x)
      final zoom6x = GameCameraConfig.getCameraZoomForWeaponZoom(6.0);

      // Higher weapon zoom must have smaller camera viewfinder zoom (reveals more arena)
      expect(zoom1x, greaterThan(zoom2x));
      expect(zoom2x, greaterThan(zoom3x));
      expect(zoom3x, greaterThan(zoom6x));
      expect(zoom6x, greaterThanOrEqualTo(0.45)); // Clamped to fit arena bounds
    });

    test('Weapon clone creates accurate independent state copy', () {
      final awp = Weapon.awp();
      awp.currentAmmo = 2;
      awp.cycleZoom(); // now 3.0

      final cloned = awp.clone();
      expect(cloned.name, 'AWP');
      expect(cloned.zoom, 3.0);
      expect(cloned.currentAmmo, 2);

      // Modifying original does not affect clone
      awp.cycleZoom(); // now 2.0
      expect(awp.zoom, 2.0);
      expect(cloned.zoom, 3.0);
    });
  });

  group('Map Scenery & Elements Tests', () {
    test('Arena contains wood cabins, stones, and bushes', () async {
      final arena = ArenaComponent();
      await arena.onLoad();
      final cabins = arena.children.whereType<WoodCabinComponent>().toList();
      final stones = arena.children.whereType<StoneComponent>().toList();
      final bushes = arena.children.whereType<BushComponent>().toList();

      expect(cabins.length, greaterThanOrEqualTo(3));
      expect(stones.length, greaterThanOrEqualTo(8));
      expect(bushes.length, greaterThanOrEqualTo(10));
    });

    test('Arena ground has bottom gaps/pits for fall hazards', () {
      final arena = ArenaComponent();
      final groundPlatforms = arena.platforms
          .where((p) => p.platformType == PlatformType.ground)
          .toList();

      // Ground is split into multiple sections separated by gaps
      expect(groundPlatforms.length, greaterThanOrEqualTo(3));
      // First section ends before second begins, confirming gap
      expect(groundPlatforms[0].position.x + groundPlatforms[0].size.x,
          lessThan(groundPlatforms[1].position.x));
    });

    test('GunPickupComponent initializes with correct weapon and availability', () {
      final pickup = GunPickupComponent(
        weaponType: WeaponType.awp,
        position: Vector2(200, 200),
      );
      expect(pickup.weaponType, WeaponType.awp);
      expect(pickup.isAvailable, isTrue);
    });

    test('Player falling into abyss below threshold height dies', () {
      final player = PlayerComponent(
        playerId: 'p1',
        name: 'Player',
        characterId: 1,
        position: Vector2(700, 1150), // in the gap, below abyss threshold
        isLocal: true,
      );

      expect(player.isDead, isFalse);
      CollisionSystem.updatePlayerPhysics(
        player: player,
        platforms: [],
        arenaWidth: 2400,
        arenaHeight: 1200,
        dt: 0.016,
      );
      expect(player.isDead, isTrue);
      expect(player.health, 0.0);
    });

    test('EnemyRadarIndicator detects alive enemies within radius', () {
      final localPlayer = PlayerComponent(
        playerId: 'local',
        name: 'Local',
        characterId: 1,
        position: Vector2(500, 500),
        isLocal: true,
      );
      final nearbyEnemy = PlayerComponent(
        playerId: 'enemy1',
        name: 'Enemy1',
        characterId: 2,
        position: Vector2(800, 500), // 300px away, within 900px radius
        isLocal: false,
      );
      final distantEnemy = PlayerComponent(
        playerId: 'enemy2',
        name: 'Enemy2',
        characterId: 3,
        position: Vector2(2000, 500), // 1500px away, outside radius
        isLocal: false,
      );

      expect(
        EnemyRadarIndicatorComponent.shouldTrackEnemy(localPlayer, nearbyEnemy),
        isTrue,
      );
      expect(
        EnemyRadarIndicatorComponent.shouldTrackEnemy(localPlayer, distantEnemy),
        isFalse,
      );
    });
  });
}
