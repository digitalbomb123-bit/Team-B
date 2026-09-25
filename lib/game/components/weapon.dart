import 'dart:math';
import 'package:flame/components.dart';

/// Weapon types specified for Team B arena combat.
enum WeaponType {
  uzi,
  ak47,
  m4a1,
  desertEagle,
  awp,
}

/// Weapon definition and fire-rate timing controller.
class Weapon {
  final WeaponType type;
  final String name;
  final double damage;
  final double zoom;
  final double reloadDuration;
  final int magazineCapacity;
  final double fireRate; // Shots per second
  final double bulletSpeed;
  final double bulletLifetime;
  final double spreadAngle; // In radians
  final double barrelLength;

  int currentAmmo;
  double _cooldown = 0.0;
  double reloadTimer = 0.0;
  bool isReloading = false;

  Weapon({
    this.type = WeaponType.uzi,
    this.name = 'Uzi',
    this.damage = 20.0,
    this.zoom = 2.0,
    this.reloadDuration = 1.5,
    this.magazineCapacity = 25,
    this.fireRate = 10.0,
    this.bulletSpeed = 950.0,
    this.bulletLifetime = 1.4,
    this.spreadAngle = 0.08,
    this.barrelLength = 22.0,
  }) : currentAmmo = magazineCapacity;

  factory Weapon.fromType(WeaponType type) {
    switch (type) {
      case WeaponType.uzi:
        return Weapon.uzi();
      case WeaponType.ak47:
        return Weapon.ak47();
      case WeaponType.m4a1:
        return Weapon.m4a1();
      case WeaponType.desertEagle:
        return Weapon.desertEagle();
      case WeaponType.awp:
        return Weapon.awp();
    }
  }

  /// Uzi: Rapid fire SMG, 20 dmg, 2x zoom, 1.5s reload
  factory Weapon.uzi() {
    return Weapon(
      type: WeaponType.uzi,
      name: 'Uzi',
      damage: 20.0,
      zoom: 2.0,
      reloadDuration: 1.5,
      magazineCapacity: 25,
      fireRate: 10.0,
      bulletSpeed: 950.0,
      bulletLifetime: 1.4,
      spreadAngle: 0.08,
      barrelLength: 22.0,
    );
  }

  /// AK-47: Heavy Assault Rifle, 35 dmg, 2.5x zoom, 2.2s reload
  factory Weapon.ak47() {
    return Weapon(
      type: WeaponType.ak47,
      name: 'AK-47',
      damage: 35.0,
      zoom: 2.5,
      reloadDuration: 2.2,
      magazineCapacity: 30,
      fireRate: 6.0,
      bulletSpeed: 1050.0,
      bulletLifetime: 1.6,
      spreadAngle: 0.05,
      barrelLength: 28.0,
    );
  }

  /// M4A1: Tactical Carbine, 28 dmg, 3x zoom, 1.8s reload
  factory Weapon.m4a1() {
    return Weapon(
      type: WeaponType.m4a1,
      name: 'M4A1',
      damage: 28.0,
      zoom: 3.0,
      reloadDuration: 1.8,
      magazineCapacity: 30,
      fireRate: 7.5,
      bulletSpeed: 1100.0,
      bulletLifetime: 1.6,
      spreadAngle: 0.03,
      barrelLength: 29.0,
    );
  }

  /// Desert Eagle: Heavy Handgun, 60 dmg, 2x zoom, 2.0s reload
  factory Weapon.desertEagle() {
    return Weapon(
      type: WeaponType.desertEagle,
      name: 'Desert Eagle',
      damage: 60.0,
      zoom: 2.0,
      reloadDuration: 2.0,
      magazineCapacity: 7,
      fireRate: 3.0,
      bulletSpeed: 1150.0,
      bulletLifetime: 1.5,
      spreadAngle: 0.02,
      barrelLength: 20.0,
    );
  }

  /// AWP: Sniper Rifle, 100 dmg, 6x zoom, 3.0s reload
  factory Weapon.awp() {
    return Weapon(
      type: WeaponType.awp,
      name: 'AWP',
      damage: 100.0,
      zoom: 6.0,
      reloadDuration: 3.0,
      magazineCapacity: 5,
      fireRate: 0.85,
      bulletSpeed: 1600.0,
      bulletLifetime: 2.0,
      spreadAngle: 0.005,
      barrelLength: 36.0,
    );
  }

  bool get canFire => _cooldown <= 0.0 && !isReloading && currentAmmo > 0;

  double get reloadProgress =>
      isReloading && reloadDuration > 0 ? (1.0 - (reloadTimer / reloadDuration)).clamp(0.0, 1.0) : 1.0;

  void startReload() {
    if (isReloading || currentAmmo >= magazineCapacity) return;
    isReloading = true;
    reloadTimer = reloadDuration;
  }

  void update(double dt) {
    if (_cooldown > 0.0) {
      _cooldown -= dt;
      if (_cooldown < 0.0) _cooldown = 0.0;
    }

    if (isReloading) {
      reloadTimer -= dt;
      if (reloadTimer <= 0.0) {
        isReloading = false;
        reloadTimer = 0.0;
        currentAmmo = magazineCapacity;
      }
    }
  }

  /// Attempts to fire a shot. Returns the calculated bullet trajectory or null if on cooldown/empty.
  WeaponShotData? fire({
    required Vector2 muzzlePosition,
    required double baseAngle,
    required String shooterId,
  }) {
    if (isReloading) return null;

    if (currentAmmo <= 0) {
      startReload();
      return null;
    }

    if (!canFire) return null;

    // Consume round
    currentAmmo--;

    // Reset cooldown based on fire rate
    _cooldown = 1.0 / fireRate;

    // Auto-reload when last round is fired
    if (currentAmmo <= 0) {
      startReload();
    }

    // Apply minor configurable weapon spread
    final rnd = Random();
    final effectiveAngle = baseAngle + (rnd.nextDouble() - 0.5) * spreadAngle;

    return WeaponShotData(
      shooterId: shooterId,
      weaponName: name,
      muzzlePosition: muzzlePosition.clone(),
      angle: effectiveAngle,
      speed: bulletSpeed,
      damage: damage,
      lifetime: bulletLifetime,
    );
  }

  void resetCooldown() {
    _cooldown = 0.0;
  }
}

class WeaponShotData {
  final String shooterId;
  final String weaponName;
  final Vector2 muzzlePosition;
  final double angle;
  final double speed;
  final double damage;
  final double lifetime;

  WeaponShotData({
    required this.shooterId,
    this.weaponName = 'bullet',
    required this.muzzlePosition,
    required this.angle,
    required this.speed,
    required this.damage,
    required this.lifetime,
  });
}
