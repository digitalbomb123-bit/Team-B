import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_b_shooter/game/components/bullet.dart';
import 'package:team_b_shooter/game/components/gun_pickup.dart';
import 'package:team_b_shooter/game/components/scenery_elements.dart';
import 'package:team_b_shooter/game/components/weapon.dart';
import 'package:team_b_shooter/game/components/wood_cabin.dart';
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

    test('GunPickupComponent initializes with correct weapon and availability', () {
      final pickup = GunPickupComponent(
        weaponType: WeaponType.awp,
        position: Vector2(200, 200),
      );
      expect(pickup.weaponType, WeaponType.awp);
      expect(pickup.isAvailable, isTrue);
    });
  });
}
