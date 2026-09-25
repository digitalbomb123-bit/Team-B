import 'dart:async';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../controls/input_controller.dart';
import '../multiplayer/multiplayer_client.dart';
import '../multiplayer/player_state.dart';
import 'camera/game_camera.dart';
import 'components/enemy_radar_indicator.dart';
import 'components/fart_bomb_pickup.dart';
import 'components/floating_text.dart';
import 'components/gun_pickup.dart';
import 'components/jetpack_fuel_pickup.dart';
import 'components/player.dart';
import 'components/weapon.dart';
import 'systems/collision_system.dart';
import 'systems/combat_system.dart';
import 'world/arena.dart';

/// Core Flame game loop for 2D Arena Shooter.
class MiniMilitiaGame extends FlameGame {
  final MultiplayerClient multiplayerClient;
  final InputController inputController;
  final int selectedCharacterId;
  final String playerName;

  // Arena & World Components
  late final ArenaComponent arena;
  late final CombatSystem combatSystem;
  late final PlayerComponent localPlayer;

  // Remote and Bot Player Components
  final Map<String, PlayerComponent> remotePlayers = {};

  // Subscriptions
  StreamSubscription<List<PlayerState>>? _playersSub;
  StreamSubscription<BulletNetworkEvent>? _bulletSub;

  // Stats
  int kills = 0;
  int deaths = 0;
  double _lastReportedHealth = -1;
  double _lastReportedFuel = -1;
  bool _lastReportedSuperFuel = false;
  bool _initialized = false;

  final List<Timer> _pendingTimers = [];

  void _scheduleTimer(Duration duration, void Function() callback) {
    late final Timer timer;
    timer = Timer(duration, () {
      _pendingTimers.remove(timer);
      if (isMounted) {
        callback();
      }
    });
    _pendingTimers.add(timer);
  }

  // Status callbacks for UI
  void Function(double health, double maxHealth)? onHealthChanged;
  void Function(double fuel, double maxFuel, bool isSuperFuel)? onFuelChanged;
  void Function(int kills, int deaths)? onScoreChanged;
  void Function(int count)? onFartBombCountChanged;
  void Function(double cooldown, double maxCooldown)? onPoopCooldownChanged;
  void Function(Weapon weapon)? onWeaponStateChanged;
  void Function({
    required String killerName,
    required String victimName,
    required String weapon,
    required bool isLocalKiller,
    required bool isLocalVictim,
  })? onKillFeedEvent;

  void notifyFartBombCountChanged(int count) {
    onFartBombCountChanged?.call(count);
  }

  MiniMilitiaGame({
    required this.multiplayerClient,
    required this.inputController,
    required this.selectedCharacterId,
    required this.playerName,
  });

  @override
  Color backgroundColor() => const Color(0xFF0284C7);

  @override
  Future<void> onLoad() async {
    images.prefix = '';
    await super.onLoad();

    // 1. Initialize Arena
    arena = ArenaComponent();
    await world.add(arena);

    // 2. Initialize Combat System
    combatSystem = CombatSystem(
      gameWorld: world,
      multiplayerClient: multiplayerClient,
    );

    // 3. Spawn Local Player
    final spawn = arena.getRandomSpawn(selectedCharacterId);
    localPlayer = PlayerComponent(
      playerId: multiplayerClient.localPlayerId,
      characterId: selectedCharacterId,
      name: playerName,
      position: spawn,
      isLocal: true,
      onDeath: (p) {
        deaths++;
        onScoreChanged?.call(kills, deaths);
        onHealthChanged?.call(0.0, p.maxHealth);
        _handlePlayerDeath(p);
      },
      onRespawn: (p) {
        // Pick new random spawn
        final newSpawn = arena.getRandomSpawn(DateTime.now().millisecond);
        p.position.setFrom(newSpawn);
        onHealthChanged?.call(p.health, p.maxHealth);
      },
    );
    localPlayer.onWeaponChanged = (w) {
      setZoom(w.zoom);
      onWeaponStateChanged?.call(w);
    };
    await world.add(localPlayer);

    // 4. Configure Camera & Viewport
    camera.viewfinder.position = localPlayer.position.clone();
    setZoom(localPlayer.weapon.zoom);
    camera.follow(localPlayer);

    // 5. Connect multiplayer listeners
    _setupNetworkListeners();

    // 6. Spawn initial random Fart Bomb and Jetpack Fuel pickups on arena platforms
    spawnFartBombPickup();
    spawnFartBombPickup();
    spawnJetpackFuelPickup();
    spawnJetpackFuelPickup();

    // 7. Spawn Weapon Pickups randomly distributed across platforms
    spawnGunPickups();

    // 8. Add Enemy Directional Radar Indicator
    await world.add(EnemyRadarIndicatorComponent());

    _initialized = true;
  }

  /// Spawns a Fart Bomb pickup on a random arena platform
  void spawnFartBombPickup() {
    final rnd = Random();
    final validPlatforms = arena.platforms
        .where((p) => p.size.x >= 120 && p.position.y > 100 && p.position.y < 1000)
        .toList();
    if (validPlatforms.isEmpty) return;

    final plat = validPlatforms[rnd.nextInt(validPlatforms.length)];
    final x = plat.position.x + 40 + rnd.nextDouble() * max(20.0, plat.size.x - 80);
    final y = plat.position.y - 12;

    final pickup = FartBombPickupComponent(
      position: Vector2(x, y),
      onCollected: () {
        // Schedule next random pickup after 12 seconds
        Future.delayed(const Duration(seconds: 12), () {
          if (isMounted) {
            spawnFartBombPickup();
          }
        });
      },
    );
    world.add(pickup);
  }

  /// Spawns an Additional Jetpack Fuel pickup on a random arena platform
  void spawnJetpackFuelPickup() {
    final rnd = Random();
    final validPlatforms = arena.platforms
        .where((p) => p.size.x >= 120 && p.position.y > 100 && p.position.y < 1000)
        .toList();
    if (validPlatforms.isEmpty) return;

    final plat = validPlatforms[rnd.nextInt(validPlatforms.length)];
    final x = plat.position.x + 30 + rnd.nextDouble() * max(20.0, plat.size.x - 60);
    final y = plat.position.y - 12;

    final pickup = JetpackFuelPickupComponent(
      position: Vector2(x, y),
      onCollected: () {
        // Schedule next random fuel pickup after 14 seconds
        _scheduleTimer(const Duration(seconds: 14), () {
          spawnJetpackFuelPickup();
        });
      },
    );
    world.add(pickup);
  }

  /// Spawn gun pickups randomly distributed across accessible arena platforms
  void spawnGunPickups() {
    final rnd = Random();
    final validPlatforms = arena.platforms
        .where((p) => p.size.x >= 140 && p.position.y >= 350 && p.position.y <= 1000)
        .toList()
      ..shuffle(rnd);

    if (validPlatforms.isEmpty) return;

    int platformIdx = 0;
    // 1. Ensure at least one of every gun type is placed at random accessible locations
    for (final type in WeaponType.values) {
      if (platformIdx >= validPlatforms.length) platformIdx = 0;
      final plat = validPlatforms[platformIdx++];
      final x = plat.position.x + 30 + rnd.nextDouble() * max(20.0, plat.size.x - 60);
      final y = plat.position.y - 12;
      _spawnRandomGun(type, Vector2(x, y));
    }

    // 2. Extra gun spawns across remaining platforms for weapon variety
    for (int i = 0; i < 3; i++) {
      if (platformIdx >= validPlatforms.length) platformIdx = 0;
      final plat = validPlatforms[platformIdx++];
      final x = plat.position.x + 30 + rnd.nextDouble() * max(20.0, plat.size.x - 60);
      final y = plat.position.y - 12;
      final randomType = WeaponType.values[rnd.nextInt(WeaponType.values.length)];
      _spawnRandomGun(randomType, Vector2(x, y));
    }
  }

  void _spawnRandomGun(WeaponType type, Vector2 pos) {
    final pickup = GunPickupComponent(
      position: pos,
      weaponType: type,
      onCollected: () {
        // Respawn a random weapon on a random accessible platform after 10 seconds
        _scheduleTimer(const Duration(seconds: 10), () {
          final rnd = Random();
          final validPlatforms = arena.platforms
              .where((p) => p.size.x >= 140 && p.position.y >= 350 && p.position.y <= 1000)
              .toList();
          if (validPlatforms.isNotEmpty) {
            final plat = validPlatforms[rnd.nextInt(validPlatforms.length)];
            final x = plat.position.x + 30 + rnd.nextDouble() * max(20.0, plat.size.x - 60);
            final y = plat.position.y - 12;
            final respawnType = WeaponType.values[rnd.nextInt(WeaponType.values.length)];
            _spawnRandomGun(respawnType, Vector2(x, y));
          }
        });
      },
    );
    world.add(pickup);
  }

  /// Manually trigger reload for local player's gun
  void reloadLocalWeapon() {
    localPlayer.reloadWeapon();
  }

  /// Trigger the local player's fart bomb blast
  bool triggerLocalFartBomb() {
    return localPlayer.blastFartBomb(this);
  }

  /// Trigger the local player's exclusive Jos poop trap
  bool triggerLocalPoop() {
    return localPlayer.dropPoop(this);
  }

  void _handlePlayerDeath(PlayerComponent victim) {
    final attackerId = victim.lastAttackerId;
    final weapon = victim.lastAttackerWeapon;

    String killerName = 'Unknown';
    bool isLocalKiller = false;
    final isLocalVictim = victim.isLocal;

    if (attackerId != null) {
      if (attackerId == localPlayer.playerId) {
        killerName = localPlayer.name;
        isLocalKiller = true;
        kills++;
        onScoreChanged?.call(kills, deaths);
        world.add(
          FloatingCombatTextComponent(
            position: Vector2(victim.position.x, victim.position.y - 35),
            text: '+1 KILL! 🎯',
            color: const Color(0xFF38BDF8),
            fontSize: 16.0,
          ),
        );
      } else if (remotePlayers.containsKey(attackerId)) {
        killerName = remotePlayers[attackerId]!.name;
      } else {
        final attackerState = multiplayerClient.currentPlayers
            .where((p) => p.playerId == attackerId)
            .firstOrNull;
        if (attackerState != null) {
          killerName = attackerState.name;
        } else if (victim.lastAttackerName != null &&
            victim.lastAttackerName!.isNotEmpty) {
          killerName = victim.lastAttackerName!;
        }
      }
    } else if (victim.lastAttackerName != null &&
        victim.lastAttackerName!.isNotEmpty) {
      killerName = victim.lastAttackerName!;
    }

    world.add(
      FloatingCombatTextComponent(
        position: Vector2(victim.position.x, victim.position.y - 15),
        text: '☠️ $killerName',
        color: const Color(0xFFEF4444),
        fontSize: 14.0,
      ),
    );

    onKillFeedEvent?.call(
      killerName: killerName,
      victimName: victim.name,
      weapon: weapon,
      isLocalKiller: isLocalKiller,
      isLocalVictim: isLocalVictim,
    );
  }

  void _setupNetworkListeners() {
    // Sync any players already spawned
    _syncRemotePlayers(multiplayerClient.currentPlayers);

    _playersSub = multiplayerClient.playersStream.listen((playerStates) {
      _syncRemotePlayers(playerStates);
    });

    _bulletSub = multiplayerClient.bulletStream.listen((bulletEvent) {
      combatSystem.spawnNetworkBullet(bulletEvent);
    });
  }

  void _syncRemotePlayers(List<PlayerState> states) {
    final activeIds = <String>{};

    for (final state in states) {
      if (state.playerId == localPlayer.playerId) {
        // Update local player stats if server killed/updated
        if (state.kills != kills) {
          kills = state.kills;
          onScoreChanged?.call(kills, deaths);
        }
        continue;
      }

      activeIds.add(state.playerId);

      var remote = remotePlayers[state.playerId];
      if (remote == null) {
        // Spawn newly joined remote player / bot
        remote = PlayerComponent(
          playerId: state.playerId,
          characterId: state.characterId,
          name: state.name,
          position: Vector2(state.x, state.y),
          isLocal: false,
          onDeath: (victim) => _handlePlayerDeath(victim),
        );
        remotePlayers[state.playerId] = remote;
        world.add(remote);
      } else {
        final wasDead = remote.isDead;
        // Sync position, aiming, animation, and jetpack flight
        remote.position.setValues(state.x, state.y);
        remote.facingDirection = state.facingDirection;
        remote.aimAngle = state.aimAngle;
        remote.health = state.health;
        remote.isFlying = state.isFlying;
        remote.jetpackFuel = state.jetpackFuel;
        if (!wasDead && state.isDead) {
          remote.die();
        } else {
          remote.isDead = state.isDead;
        }
      }
    }

    // Remove disconnected players
    remotePlayers.removeWhere((id, comp) {
      if (!activeIds.contains(id)) {
        comp.removeFromParent();
        return true;
      }
      return false;
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_initialized) return;

    // 1. Process Input for Local Player
    if (!localPlayer.isDead) {
      localPlayer.move(inputController.moveX);
      localPlayer.setFlying(inputController.isFlying);
      if (inputController.isJumping) {
        localPlayer.jump();
      }
      localPlayer.updateAim(inputController.aimAngle);
      localPlayer.isShooting = inputController.isShooting;

      if (inputController.isShooting) {
        final muzzle = localPlayer.getMuzzleWorldPosition();
        combatSystem.fireWeapon(
          shooter: localPlayer,
          muzzlePos: muzzle,
          angle: inputController.aimAngle,
        );
      }
    }

    // 2. Physics & Platform Collisions for Local Player
    CollisionSystem.updatePlayerPhysics(
      player: localPlayer,
      platforms: arena.platforms,
      arenaWidth: ArenaComponent.arenaWidth,
      arenaHeight: ArenaComponent.arenaHeight,
      dt: dt,
    );

    // Notify HUD only when health actually changes
    if (localPlayer.health != _lastReportedHealth) {
      _lastReportedHealth = localPlayer.health;
      onHealthChanged?.call(localPlayer.health, localPlayer.maxHealth);
    }

    // Notify HUD when jetpack fuel changes
    final currentFuelDisplay = localPlayer.superFuelTimer > 0
        ? (localPlayer.superFuelTimer / 10.0 * PlayerComponent.maxJetpackFuel)
        : localPlayer.jetpackFuel;
    if ((currentFuelDisplay - _lastReportedFuel).abs() > 0.5 ||
        localPlayer.hasSuperFuel != _lastReportedSuperFuel) {
      _lastReportedFuel = currentFuelDisplay;
      _lastReportedSuperFuel = localPlayer.hasSuperFuel;
      onFuelChanged?.call(
        currentFuelDisplay,
        PlayerComponent.maxJetpackFuel,
        localPlayer.hasSuperFuel,
      );
    }

    // Notify Jos poop cooldown
    if (localPlayer.isJos) {
      onPoopCooldownChanged?.call(
        localPlayer.poopCooldownTimer,
        PlayerComponent.maxPoopCooldown,
      );
    }

    // 3. Update Combat System & Bullet Hits
    final allPlayers = [localPlayer, ...remotePlayers.values];
    combatSystem.update(
      players: allPlayers,
      platforms: arena.platforms,
    );

    // Notify weapon state (ammo, reloading)
    onWeaponStateChanged?.call(localPlayer.weapon);

    // 4. Broadcast Local Player State Over Network
    multiplayerClient.sendPlayerUpdate(
      PlayerState(
        playerId: localPlayer.playerId,
        characterId: localPlayer.characterId,
        name: localPlayer.name,
        x: localPlayer.position.x,
        y: localPlayer.position.y,
        vx: localPlayer.velocity.x,
        vy: localPlayer.velocity.y,
        facingDirection: localPlayer.facingDirection,
        aimAngle: localPlayer.aimAngle,
        currentAnimation: localPlayer.currentAnimation.name,
        isShooting: localPlayer.isShooting,
        isFlying: localPlayer.isFlying,
        jetpackFuel: localPlayer.jetpackFuel,
        health: localPlayer.health,
        maxHealth: localPlayer.maxHealth,
        isDead: localPlayer.isDead,
        kills: kills,
        deaths: deaths,
      ),
    );
  }

  /// Change camera zoom at runtime based on weapon zoom level
  void setZoom(double weaponZoom) {
    final cameraZoom = GameCameraConfig.getCameraZoomForWeaponZoom(weaponZoom);
    GameCameraConfig.cameraZoom = cameraZoom;
    camera.viewfinder.zoom = cameraZoom;
  }

  /// Toggle weapon zoom (cycle levels) and update camera.
  void toggleZoom() {
    localPlayer.weapon.cycleZoom();
    setZoom(localPlayer.weapon.zoom);
    onWeaponStateChanged?.call(localPlayer.weapon);
  }

  @override
  void onRemove() {
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
    _playersSub?.cancel();
    _bulletSub?.cancel();
    combatSystem.clear();
    super.onRemove();
  }
}
