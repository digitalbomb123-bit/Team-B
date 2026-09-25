import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../mini_militia_game.dart';
import 'floating_text.dart';
import 'player.dart';
import 'weapon.dart';

/// An interactive weapon pickup placed on arena platforms.
/// Allows players to equip Uzi, AK-47, M4A1, Desert Eagle, or AWP.
class GunPickupComponent extends PositionComponent with HasGameReference<MiniMilitiaGame> {
  final WeaponType weaponType;
  final VoidCallback? onCollected;
  double _time = 0.0;
  bool _collected = false;
  bool get isAvailable => !_collected;
  final double _baseY;

  late final String _weaponName;
  late final double _weaponZoom;
  late final double _weaponDamage;

  GunPickupComponent({
    required Vector2 position,
    required this.weaponType,
    this.onCollected,
  })  : _baseY = position.y,
        super(
          position: position.clone(),
          size: Vector2(50, 36),
          anchor: Anchor.center,
        ) {
    final tempWeapon = Weapon.fromType(weaponType);
    _weaponName = tempWeapon.name;
    _weaponZoom = tempWeapon.zoom;
    _weaponDamage = tempWeapon.damage;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;

    _time += dt;

    // Smooth floating bobbing motion
    position.y = _baseY + sin(_time * 3.2) * 5.0;

    // Check collision with local player
    final player = game.localPlayer;
    if (!player.isDead) {
      final dist = position.distanceTo(player.position);
      if (dist < 42.0) {
        _collect(player);
      }
    }
  }

  void _collect(PlayerComponent player) {
    if (_collected) return;
    _collected = true;

    player.equipWeapon(Weapon.fromType(weaponType));
    game.setZoom(_weaponZoom);

    // Floating combat text announcement
    game.world.add(
      FloatingCombatTextComponent(
        position: Vector2(position.x, position.y - 36),
        text: '🔫 $_weaponName [${_weaponZoom.toStringAsFixed(1)}x ZOOM]!',
        color: const Color(0xFF38BDF8),
        fontSize: 14.0,
      ),
    );

    onCollected?.call();
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_collected) return;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // 1. Glowing Holo Platform Base
    final glowPulse = (sin(_time * 4.0) + 1.0) * 0.5;
    final haloPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.15 + glowPulse * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, 24 + glowPulse * 4, haloPaint);

    final basePaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-24, -12, 48, 24),
      const Radius.circular(6),
    );
    canvas.drawRRect(bgRect, basePaint);
    canvas.drawRRect(bgRect, borderPaint);

    // 2. Render Gun Silhouette
    _renderGunSilhouette(canvas);

    // 3. Name & Zoom Label above
    final textSpan = TextSpan(
      text: '$_weaponName (${_weaponZoom.toStringAsFixed(1)}x)',
      style: const TextStyle(
        color: Color(0xFFE2E8F0),
        fontSize: 8.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
        shadows: [
          Shadow(color: Colors.black, blurRadius: 4),
        ],
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -26));

    // 4. Damage Tag below
    final dmgSpan = TextSpan(
      text: '${_weaponDamage.toInt()} DMG',
      style: const TextStyle(
        color: Color(0xFFFBBF24),
        fontSize: 7.5,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black, blurRadius: 3),
        ],
      ),
    );
    final dmgTp = TextPainter(
      text: dmgSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    dmgTp.paint(canvas, Offset(-dmgTp.width / 2, 14));

    canvas.restore();
  }

  void _renderGunSilhouette(Canvas canvas) {
    final metalPaint = Paint()..color = const Color(0xFF94A3B8);
    final accentPaint = Paint()..color = const Color(0xFF38BDF8);

    switch (weaponType) {
      case WeaponType.awp:
        // Long sniper rifle with scope
        canvas.drawRect(const Rect.fromLTWH(-16, -2, 32, 3), metalPaint);
        canvas.drawRect(const Rect.fromLTWH(-4, -6, 12, 2.5), accentPaint); // Scope
        canvas.drawRect(const Rect.fromLTWH(-14, 1, 6, 5), metalPaint); // Stock
        break;
      case WeaponType.desertEagle:
        // Heavy pistol
        canvas.drawRect(const Rect.fromLTWH(-8, -4, 16, 5), metalPaint);
        canvas.drawRect(const Rect.fromLTWH(-6, 1, 6, 7), accentPaint); // Grip
        break;
      case WeaponType.ak47:
        // Curved magazine assault rifle
        canvas.drawRect(const Rect.fromLTWH(-14, -3, 26, 4), metalPaint);
        canvas.drawRect(const Rect.fromLTWH(-14, 1, 6, 5), Paint()..color = const Color(0xFFB45309)); // Wood stock
        canvas.drawRect(const Rect.fromLTWH(0, 1, 4, 8), accentPaint); // Curved mag
        break;
      case WeaponType.m4a1:
        // Modern carbine with sight
        canvas.drawRect(const Rect.fromLTWH(-14, -3, 27, 4), metalPaint);
        canvas.drawRect(const Rect.fromLTWH(-2, -6, 8, 2.5), accentPaint); // Optic
        canvas.drawRect(const Rect.fromLTWH(2, 1, 4, 7), metalPaint); // Mag
        break;
      case WeaponType.uzi:
        // Compact submachine gun
        canvas.drawRect(const Rect.fromLTWH(-10, -4, 20, 5), metalPaint);
        canvas.drawRect(const Rect.fromLTWH(-2, 1, 4, 9), accentPaint); // Straight mag
        break;
    }
  }
}
