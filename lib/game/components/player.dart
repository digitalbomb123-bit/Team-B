import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../characters/character_definition.dart';
import '../../characters/character_registry.dart';
import '../mini_militia_game.dart';
import 'floating_text.dart';
import 'toxic_gas_cloud.dart';
import 'weapon.dart';
import '../../audio/audio_manager.dart';

enum PlayerAnimState {
  idle,
  run,
  jump,
  fall,
  shoot,
  death,
}

/// Player component representing both local hero and remote/bot soldiers.
/// Modular architecture separates BODY, FACE, and WEAPON.
class PlayerComponent extends PositionComponent with HasGameReference {
  // Identifiers
  final String playerId;
  final int characterId;
  final String name;
  final bool isLocal;

  // Movement Constants (Configurable, centralized)
  static const double moveSpeed = 240.0;
  static const double jumpForce = -520.0;
  static const double gravity = 1100.0;
  static const double airControl = 0.85;
  static const double maxFallSpeed = 750.0;

  // Physics & State
  Vector2 velocity = Vector2.zero();
  double health = 100.0;
  double maxHealth = 100.0;
  double facingDirection = 1.0; // 1.0 = right, -1.0 = left
  double aimAngle = 0.0; // Radians
  PlayerAnimState currentAnimation = PlayerAnimState.idle;
  bool isShooting = false;
  bool isDead = false;
  bool isGrounded = false;

  // Weapon & Combat
  Weapon weapon = Weapon.uzi();
  void Function(Weapon)? onWeaponChanged;
  double muzzleFlashTimer = 0.0;
  double respawnCountdown = 0.0;
  static const double respawnDuration = 3.0;

  // Jetpack & Flight System
  double jetpackFuel = 100.0;
  static const double maxJetpackFuel = 100.0;
  static const double jetpackBurnRate = 30.0; // Fuel burnt per sec (~3.3s full burn)
  static const double jetpackRechargeRate = 22.0; // Fuel recharged per sec (~4.5s full refill)
  static const double jetpackThrust = -2200.0; // Upward acceleration countering gravity
  static const double maxFlySpeed = -420.0; // Terminal upward flight speed
  bool isFlying = false;
  double _jetpackCooldownTimer = 0.0;
  static const double jetpackRechargeDelay = 0.5; // Refill delay in seconds

  // Super Jetpack Fuel (Map Pickup lasting up to 10 seconds)
  double superFuelTimer = 0.0;
  bool get hasSuperFuel => superFuelTimer > 0.0;

  void applySuperFuel(double duration) {
    superFuelTimer = max(superFuelTimer, duration);
    jetpackFuel = maxJetpackFuel;
  }

  // Fart Bomb & Toxic Mechanics
  int fartBombCount = 0;
  double fartAnimationTimer = 0.0;
  bool get isFarting => fartAnimationTimer > 0;
  double poisonFlashTimer = 0.0;
  bool get isPoisoned => poisonFlashTimer > 0;

  // Combat Attacker Tracking (for "who killed who")
  String? lastAttackerId;
  String? lastAttackerName;
  String lastAttackerWeapon = 'bullet';

  // Visual Assets & Overlay
  Sprite? faceSprite;
  late final CharacterDefinition characterDef;

  // Animation time accumulators
  double _animTime = 0.0;

  // Collision Box Dimensions (Logical coordinates)
  static const double playerWidth = 36.0;
  static const double playerHeight = 58.0;

  // Callbacks
  void Function(PlayerComponent player)? onDeath;
  void Function(PlayerComponent player)? onRespawn;

  PlayerComponent({
    required this.playerId,
    required this.characterId,
    required this.name,
    required Vector2 position,
    this.isLocal = false,
    this.onDeath,
    this.onRespawn,
  }) : super(
          position: position,
          size: Vector2(playerWidth, playerHeight),
          anchor: Anchor.bottomCenter,
        ) {
    characterDef = CharacterRegistry.getById(characterId);
  }

  Rect get collisionRect => Rect.fromCenter(
        center: Offset(position.x, position.y - playerHeight / 2),
        width: playerWidth,
        height: playerHeight,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loadFaceSprite();
  }

  void _loadFaceSprite() async {
    try {
      final byteData = await rootBundle.load(characterDef.faceAsset);
      final codec =
          await ui.instantiateImageCodec(byteData.buffer.asUint8List());
      final frameInfo = await codec.getNextFrame();
      faceSprite = Sprite(frameInfo.image);
    } catch (_) {
      // Clean fallback face renders when faceSprite is null
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    weapon.update(dt);
    if (muzzleFlashTimer > 0) {
      muzzleFlashTimer -= dt;
    }
    if (fartAnimationTimer > 0) {
      fartAnimationTimer -= dt;
    }
    if (poisonFlashTimer > 0) {
      poisonFlashTimer -= dt;
    }

    if (isDead) {
      currentAnimation = PlayerAnimState.death;
      isFlying = false;
      if (respawnCountdown > 0) {
        respawnCountdown -= dt;
        if (respawnCountdown <= 0) {
          respawn();
        }
      }
      return;
    }

    _animTime += dt;

    // --- JETPACK FLIGHT & AUTOMATIC FUEL REFILL ---
    if (isFlying && (jetpackFuel > 0 || superFuelTimer > 0)) {
      if (superFuelTimer > 0) {
        superFuelTimer = max(0.0, superFuelTimer - dt);
        jetpackFuel = maxJetpackFuel; // Maintain full standard fuel during super boost
      } else {
        jetpackFuel = max(0.0, jetpackFuel - jetpackBurnRate * dt);
      }
      _jetpackCooldownTimer = jetpackRechargeDelay;
      velocity.y = max(maxFlySpeed, velocity.y + jetpackThrust * dt);
      isGrounded = false;
      if (jetpackFuel <= 0 && superFuelTimer <= 0) {
        isFlying = false;
      }
    } else {
      isFlying = false;
      if (_jetpackCooldownTimer > 0) {
        _jetpackCooldownTimer -= dt;
      } else if (jetpackFuel < maxJetpackFuel) {
        // Automatically refill fuel over time!
        jetpackFuel = min(maxJetpackFuel, jetpackFuel + jetpackRechargeRate * dt);
      }
    }

    // Determine animation state based on physics
    if (!isGrounded) {
      currentAnimation = velocity.y < 0 ? PlayerAnimState.jump : PlayerAnimState.fall;
    } else if (isShooting) {
      currentAnimation = PlayerAnimState.shoot;
    } else if (velocity.x.abs() > 10.0) {
      currentAnimation = PlayerAnimState.run;
    } else {
      currentAnimation = PlayerAnimState.idle;
    }
  }

  /// Activate or deactivate jetpack flight
  void setFlying(bool flying) {
    if (isDead) {
      isFlying = false;
      return;
    }
    if (flying && (jetpackFuel > 0 || superFuelTimer > 0)) {
      isFlying = true;
      isGrounded = false;
    } else {
      isFlying = false;
    }
  }

  /// Apply horizontal input movement
  void move(double directionX) {
    if (isDead) return;

    final control = isGrounded ? 1.0 : airControl;
    velocity.x = directionX * moveSpeed * control;

    // Face the direction of aiming or moving
    if (aimAngle.abs() > pi / 2) {
      facingDirection = -1.0;
    } else {
      facingDirection = 1.0;
    }
  }

  /// Jump if grounded, or fire jetpack if already airborne
  void jump() {
    if (isDead) return;
    if (isGrounded) {
      velocity.y = jumpForce;
      isGrounded = false;
    } else {
      setFlying(true);
    }
  }

  /// Update aiming angle from controls
  void updateAim(double angle) {
    aimAngle = angle;
    if (cos(aimAngle) < -0.05) {
      facingDirection = -1.0;
    } else if (cos(aimAngle) > 0.05) {
      facingDirection = 1.0;
    }
  }

  /// Take damage from incoming bullets or environmental hazards
  void takeDamage(double amount, {String? attackerId, String? attackerName, String weapon = 'bullet'}) {
    if (isDead) return;

    if (attackerId != null) {
      lastAttackerId = attackerId;
      lastAttackerName = attackerName;
      lastAttackerWeapon = weapon;
    }

    health = max(0.0, health - amount);
    if (health <= 0.0) {
      die();
    }
  }

  /// Trigger death
  void die() {
    if (isDead) return;
    isDead = true;
    fartAnimationTimer = 0.0;
    poisonFlashTimer = 0.0;
    superFuelTimer = 0.0;
    health = 0.0;
    velocity.setZero();
    currentAnimation = PlayerAnimState.death;
    respawnCountdown = respawnDuration;
    if (isLocal) {
      AudioManager.playDeathSound();
    }
    onDeath?.call(this);
  }

  /// Equips a new weapon (e.g. from map pickup)
  void equipWeapon(Weapon newWeapon) {
    weapon = newWeapon;
    onWeaponChanged?.call(weapon);
  }

  /// Manually trigger weapon reload
  void reloadWeapon() {
    weapon.startReload();
  }

  /// Respawn player with full health
  void respawn({Vector2? newPosition}) {
    isDead = false;
    fartAnimationTimer = 0.0;
    poisonFlashTimer = 0.0;
    lastAttackerId = null;
    lastAttackerName = null;
    lastAttackerWeapon = 'bullet';
    health = maxHealth;
    velocity.setZero();
    currentAnimation = PlayerAnimState.idle;
    if (newPosition != null) {
      position.setFrom(newPosition);
    }
    onRespawn?.call(this);
  }

  /// Blasts a fart bomb releasing a lingering toxic green gas cloud and comically launching the player
  bool blastFartBomb(MiniMilitiaGame game) {
    if (fartBombCount <= 0 || isDead) return false;
    fartBombCount--;
    fartAnimationTimer = 0.65;

    // Fart jet propulsion
    velocity.x += facingDirection * 170.0;
    velocity.y -= 110.0;
    isGrounded = false;

    // Spawn toxic gas cloud right behind the player
    final cloudPos = Vector2(position.x - facingDirection * 18, position.y - 24);
    game.world.add(
      ToxicGasCloudComponent(
        position: cloudPos,
        shooterId: playerId,
        maxRadius: 85.0,
        lifetime: 7.0,
      ),
    );

    // Comical floating sound text
    game.world.add(
      FloatingCombatTextComponent(
        position: Vector2(position.x, position.y - 50),
        text: '💨 PFFFFFFFT!',
        color: const Color(0xFFBEF264),
        fontSize: 13,
      ),
    );

    game.notifyFartBombCountChanged(fartBombCount);
    return true;
  }

  Vector2 getMuzzleWorldPosition() {
    final armPivot = Vector2(position.x, position.y - 32);
    final offset = Vector2(cos(aimAngle), sin(aimAngle)) * weapon.barrelLength;
    return armPivot + offset;
  }

  // ==========================================
  // MODULAR RENDERING: BODY, FACE, WEAPON
  // ==========================================
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();

    // Translate local origin to the soldier's feet (Anchor.bottomCenter)
    canvas.translate(size.x / 2, size.y);

    // Render name tag
    _renderNameTag(canvas);

    // Render overhead health bar for enemies
    if (!isLocal && !isDead) {
      _renderEnemyHealthBar(canvas);
    }

    // Apply facing flip
    canvas.scale(facingDirection, 1.0);

    if (isDead) {
      // Death pose / knocked down
      canvas.save();
      canvas.translate(0, -12);
      canvas.rotate(-pi / 2);
      _renderBody(canvas);
      _renderFace(canvas);
      _renderWeapon(canvas);
      canvas.restore();
    } else {
      if (isFarting) {
        _renderFartEffect(canvas);
      }
      if (poisonFlashTimer > 0) {
        _renderPoisonAura(canvas);
      }
      canvas.save();
      if (isFarting) {
        // Lean forward comically while pushing fart
        canvas.rotate(0.20);
      }
      // Alive rendering in 3 distinct layers:
      _renderBody(canvas);
      _renderFace(canvas);
      _renderWeapon(canvas);
      canvas.restore();
    }

    canvas.restore();
  }

  void _renderFartEffect(Canvas canvas) {
    final progress = 1.0 - (fartAnimationTimer / 0.65).clamp(0.0, 1.0);
    final puffScale = 0.5 + progress * 1.5;

    final puffPaint1 = Paint()
      ..color = const Color(0xFF84CC16).withValues(alpha: (1.0 - progress) * 0.85);
    final puffPaint2 = Paint()
      ..color = const Color(0xFFEAB308).withValues(alpha: (1.0 - progress) * 0.75);
    final puffPaint3 = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: (1.0 - progress) * 0.90);

    final streakPaint = Paint()
      ..color = const Color(0xFFBEF264).withValues(alpha: (1.0 - progress))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const bx = -14.0;
    const by = -22.0;

    canvas.drawLine(const Offset(bx, by), Offset(bx - 20 * puffScale, by - 10), streakPaint);
    canvas.drawLine(const Offset(bx, by), Offset(bx - 26 * puffScale, by), streakPaint);
    canvas.drawLine(const Offset(bx, by), Offset(bx - 20 * puffScale, by + 12), streakPaint);

    canvas.drawCircle(Offset(bx - 12 * puffScale, by - 6), 10 * puffScale, puffPaint1);
    canvas.drawCircle(Offset(bx - 20 * puffScale, by + 4), 14 * puffScale, puffPaint2);
    canvas.drawCircle(Offset(bx - 28 * puffScale, by - 2), 16 * puffScale, puffPaint3);
  }

  void _renderPoisonAura(Canvas canvas) {
    final poisonPaint = Paint()
      ..color = const Color(0xFF84CC16).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -28), width: 34, height: 56),
      poisonPaint,
    );
  }

  /// 1. BODY RENDERING (Shared across all characters)
  void _renderBody(Canvas canvas) {
    final paintArmor = Paint()..color = const Color(0xFF2D3748); // Tactical dark slate
    final paintVest = Paint()..color = const Color(0xFF3B4D3C); // Military camo green
    final paintStraps = Paint()..color = const Color(0xFF1A202C); // Black straps
    final paintBoots = Paint()..color = const Color(0xFF171923); // Combat boots
    final paintSkin = Paint()..color = const Color(0xFFE2B897); // Skin tone hands/neck

    // --- LEGS & ANIMATION ---
    double leg1Angle = 0.0;
    double leg2Angle = 0.0;

    switch (currentAnimation) {
      case PlayerAnimState.run:
        leg1Angle = sin(_animTime * 12.0) * 0.45;
        leg2Angle = -leg1Angle;
        break;
      case PlayerAnimState.jump:
        leg1Angle = 0.3;
        leg2Angle = -0.2;
        break;
      case PlayerAnimState.fall:
        leg1Angle = -0.25;
        leg2Angle = 0.35;
        break;
      default:
        leg1Angle = 0.05;
        leg2Angle = -0.05;
        break;
    }

    // Left / Back Leg
    canvas.save();
    canvas.translate(-4, -20);
    canvas.rotate(leg2Angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-3, 0, 7, 20), const Radius.circular(3)),
      paintArmor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-3, 13, 8, 8), const Radius.circular(2)),
      paintBoots,
    );
    canvas.restore();

    // Right / Front Leg
    canvas.save();
    canvas.translate(4, -20);
    canvas.rotate(leg1Angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 0, 7, 20), const Radius.circular(3)),
      paintArmor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 13, 8, 8), const Radius.circular(2)),
      paintBoots,
    );
    canvas.restore();

    // --- TORSO / CHEST ---
    // Torso breathing bob
    final bob = (currentAnimation == PlayerAnimState.idle) ? sin(_animTime * 4.0) * 1.0 : 0.0;

    canvas.save();
    canvas.translate(0, -22 + bob);

    // --- JETPACK BACKPACK & THRUST EXHAUST ---
    final paintJetpack = Paint()..color = const Color(0xFF1E293B);
    final paintJetpackDetail = Paint()..color = const Color(0xFF38BDF8);
    // Jetpack canister mounted on the back
    final jetpackRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-15, -19, 7, 18),
      const Radius.circular(3),
    );
    canvas.drawRRect(jetpackRect, paintJetpack);

    // Jetpack exhaust nozzle
    final nozzleRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-14, -1, 5, 3),
      const Radius.circular(1),
    );
    canvas.drawRRect(nozzleRect, paintJetpackDetail);

    // Fiery rocket flame exhaust when flying!
    if (isFlying && (jetpackFuel > 0 || superFuelTimer > 0)) {
      final flicker = sin(_animTime * 35.0) * 3.5;
      final isSuper = superFuelTimer > 0;
      final flameLen = (isSuper ? 24.0 : 16.0) + flicker;

      // Outer plasma flame (orange/red glow or electric cyan in super mode)
      final paintOuterFlame = Paint()
        ..color = isSuper ? const Color(0xFF00E5FF) : const Color(0xFFFF5722)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      final outerPath = Path()
        ..moveTo(-15, 2)
        ..lineTo(-9, 2)
        ..lineTo(-12, 2 + flameLen)
        ..close();
      canvas.drawPath(outerPath, paintOuterFlame);

      // Inner white/yellow fiery core
      final paintInnerFlame = Paint()
        ..color = isSuper ? Colors.white : const Color(0xFFFFEB3B);
      final innerPath = Path()
        ..moveTo(-14, 2)
        ..lineTo(-10, 2)
        ..lineTo(-12, 2 + flameLen * 0.6)
        ..close();
      canvas.drawPath(innerPath, paintInnerFlame);
    }

    // Tactical Body Vest
    final vestRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-10, -20, 20, 22),
      const Radius.circular(4),
    );
    canvas.drawRRect(vestRect, paintVest);

    // Chest armor plate
    final plateRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-7, -18, 14, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(plateRect, paintArmor);

    // Tactical Harness Straps
    canvas.drawLine(const Offset(-8, -20), const Offset(-2, -6), Paint()..color = paintStraps.color..strokeWidth = 2);
    canvas.drawLine(const Offset(8, -20), const Offset(2, -6), Paint()..color = paintStraps.color..strokeWidth = 2);

    // Tactical Belt
    canvas.drawRect(const Rect.fromLTWH(-10, 0, 20, 3), paintStraps);

    // Neck anchor
    canvas.drawRect(const Rect.fromLTWH(-3, -24, 6, 5), paintSkin);

    canvas.restore();
  }

  /// 2. FACE RENDERING (Independently rendered overlay from PNG asset)
  void _renderFace(Canvas canvas) {
    final bob = (currentAnimation == PlayerAnimState.idle) ? sin(_animTime * 4.0) * 1.0 : 0.0;
    const double headCenterY = -48.0;
    const double headSize = 28.0;

    canvas.save();
    canvas.translate(0, headCenterY + bob);

    if (faceSprite != null) {
      // Draw the independent face PNG cleanly centered over the head anchor
      faceSprite!.render(
        canvas,
        position: Vector2(-headSize / 2, -headSize / 2),
        size: Vector2(headSize, headSize),
      );
    } else {
      // Fallback clean soldier face if sprite loading is pending
      final paintSkin = Paint()..color = const Color(0xFFF3C099);
      final paintHelmet = Paint()..color = const Color(0xFF2C3E50);
      canvas.drawCircle(Offset.zero, 11, paintSkin);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 12),
        pi,
        pi,
        true,
        paintHelmet,
      );
    }

    canvas.restore();
  }

  /// 3. WEAPON RENDERING (Rifle aimed toward aimAngle)
  void _renderWeapon(Canvas canvas) {
    final bob = (currentAnimation == PlayerAnimState.idle) ? sin(_animTime * 4.0) * 1.0 : 0.0;
    const double shoulderY = -34.0;

    canvas.save();
    canvas.translate(2, shoulderY + bob);

    // Weapon angle relative to facing direction
    final effectiveAngle = facingDirection > 0 ? aimAngle : pi - aimAngle;
    canvas.rotate(effectiveAngle);

    final paintMetal = Paint()..color = const Color(0xFF1E293B);
    final paintGunStock = Paint()..color = const Color(0xFF475569);
    final paintGunDetail = Paint()..color = const Color(0xFF0F172A);

    switch (weapon.type) {
      case WeaponType.awp:
        // AWP: Long Sniper with large scope and green/black body
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -3, 14, 6), const Radius.circular(2)),
          Paint()..color = const Color(0xFF14532D), // Green sniper body
        );
        canvas.drawRect(const Rect.fromLTWH(6, -2, 28, 4), paintMetal); // Long heavy barrel
        canvas.drawRect(const Rect.fromLTWH(0, -7, 14, 3), Paint()..color = const Color(0xFF38BDF8)); // Scope
        canvas.drawRect(const Rect.fromLTWH(2, 2, 4, 6), paintGunDetail);
        break;

      case WeaponType.desertEagle:
        // Desert Eagle: Heavy Chrome Handgun
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -4, 16, 7), const Radius.circular(2)),
          Paint()..color = const Color(0xFF94A3B8), // Chrome slide
        );
        canvas.drawRect(const Rect.fromLTWH(-1, 2, 5, 8), paintGunDetail); // Grip
        break;

      case WeaponType.ak47:
        // AK-47: Wooden buttstock, dark receiver, curved banana mag
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -3, 13, 6), const Radius.circular(2)),
          Paint()..color = const Color(0xFFB45309), // Wood stock
        );
        canvas.drawRect(const Rect.fromLTWH(6, -2, 20, 4), paintMetal);
        canvas.save();
        canvas.rotate(0.35);
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(1, 1, 4, 10), const Radius.circular(1.5)),
          paintGunDetail,
        );
        canvas.restore();
        break;

      case WeaponType.m4a1:
        // M4A1: Modern tactical carbine with optic
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -3, 14, 6), const Radius.circular(2)),
          paintGunStock,
        );
        canvas.drawRect(const Rect.fromLTWH(8, -2, 19, 4), paintMetal);
        canvas.drawRect(const Rect.fromLTWH(2, -6, 8, 2.5), Paint()..color = const Color(0xFF38BDF8)); // Optic sight
        canvas.drawRect(const Rect.fromLTWH(3, 2, 4, 8), paintGunDetail);
        break;

      case WeaponType.uzi:
        // Uzi: Compact SMG
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -4, 16, 7), const Radius.circular(2)),
          paintMetal,
        );
        canvas.drawRect(const Rect.fromLTWH(10, -2, 10, 3.5), paintGunStock);
        canvas.drawRect(const Rect.fromLTWH(2, 2, 4, 10), paintGunDetail); // Straight vertical mag
        break;
    }

    // Soldier Hand gripping weapon
    final paintHand = Paint()..color = const Color(0xFFE2B897);
    canvas.drawCircle(const Offset(4, 0), 3.5, paintHand);

    // Muzzle Flash Effect
    if (muzzleFlashTimer > 0) {
      final muzzleX = weapon.barrelLength;
      final paintFlash = Paint()
        ..color = const Color(0xFFFFCC00).withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(muzzleX, 0), 7, paintFlash);

      final paintCore = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(muzzleX, 0), 3, paintCore);
    }

    canvas.restore();
  }

  /// Render Name Tag above the player's head (without overhead health/fuel bars)
  void _renderNameTag(Canvas canvas) {
    const double topOffset = -66.0;

    // Name Text Tag
    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: isLocal ? const Color(0xFF67E8F9) : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 3),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, topOffset),
    );
  }

  /// Render overhead health bar for enemy soldiers (without numbers, pure tactical bar)
  void _renderEnemyHealthBar(Canvas canvas) {
    if (isLocal || isDead) return;

    const double barWidth = 32.0;
    const double barHeight = 4.0;
    const double topOffset = -53.0; // Positioned right below the name tag (-66.0)

    // 1. Dark container background with border
    final bgPaint = Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.9);
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-barWidth / 2, topOffset, barWidth, barHeight),
      const Radius.circular(2),
    );
    canvas.drawRRect(bgRect, bgPaint);
    canvas.drawRRect(bgRect, borderPaint);

    // 2. Health fill based on ratio
    final healthRatio = (health / maxHealth).clamp(0.0, 1.0);
    if (healthRatio > 0.0) {
      final fillWidth = (barWidth - 1.6) * healthRatio;
      final Color fillColor;
      if (isPoisoned) {
        fillColor = const Color(0xFFA3E635); // Toxic Lime flash when poisoned
      } else if (healthRatio > 0.5) {
        fillColor = const Color(0xFF22C55E); // Healthy Green
      } else if (healthRatio > 0.25) {
        fillColor = const Color(0xFFFBBF24); // Warning Amber
      } else {
        fillColor = const Color(0xFFEF4444); // Critical Red
      }

      final fillPaint = Paint()..color = fillColor;
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(-barWidth / 2 + 0.8, topOffset + 0.8, fillWidth, barHeight - 1.6),
        const Radius.circular(1.2),
      );
      canvas.drawRRect(fillRect, fillPaint);
    }
  }
}
