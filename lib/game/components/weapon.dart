import 'dart:math';
import 'package:flame/components.dart';

/// Weapon definition and fire-rate timing controller.
class Weapon {
  final String name;
  final double damage;
  final double fireRate; // Shots per second
  final double bulletSpeed;
  final double bulletLifetime;
  final double spreadAngle; // In radians
  final double barrelLength;

  double _cooldown = 0.0;

  Weapon({
    this.name = 'Tactical Assault Rifle',
    this.damage = 20.0,
    this.fireRate = 5.0, // 5 rounds/sec = 0.2s cooldown
    this.bulletSpeed = 900.0,
    this.bulletLifetime = 1.6,
    this.spreadAngle = 0.04,
    this.barrelLength = 26.0,
  });

  bool get canFire => _cooldown <= 0.0;

  void update(double dt) {
    if (_cooldown > 0.0) {
      _cooldown -= dt;
      if (_cooldown < 0.0) _cooldown = 0.0;
    }
  }

  /// Attempts to fire a shot. Returns the calculated bullet trajectory or null if on cooldown.
  WeaponShotData? fire({
    required Vector2 muzzlePosition,
    required double baseAngle,
    required String shooterId,
  }) {
    if (!canFire) return null;

    // Reset cooldown based on fire rate
    _cooldown = 1.0 / fireRate;

    // Apply minor configurable weapon spread
    final rnd = Random();
    final effectiveAngle = baseAngle + (rnd.nextDouble() - 0.5) * spreadAngle;

    return WeaponShotData(
      shooterId: shooterId,
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
  final Vector2 muzzlePosition;
  final double angle;
  final double speed;
  final double damage;
  final double lifetime;

  WeaponShotData({
    required this.shooterId,
    required this.muzzlePosition,
    required this.angle,
    required this.speed,
    required this.damage,
    required this.lifetime,
  });
}
