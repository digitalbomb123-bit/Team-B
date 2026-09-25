import 'dart:async';
import 'dart:math';
import 'multiplayer_client.dart';
import 'player_state.dart';
import '../characters/character_registry.dart';

/// Mock multiplayer client simulating local bots and network state for up to 10 players.
class MockMultiplayerClient implements MultiplayerClient {
  final _playersController = StreamController<List<PlayerState>>.broadcast();
  final _bulletController = StreamController<BulletNetworkEvent>.broadcast();

  final Map<String, PlayerState> _players = {};
  Timer? _simulationTimer;
  final Random _rnd = Random();

  String _localPlayerId = 'local_p1';
  int _localCharacterId = 1;
  String _localPlayerName = 'Hero';

  @override
  Stream<List<PlayerState>> get playersStream => _playersController.stream;

  @override
  Stream<BulletNetworkEvent> get bulletStream => _bulletController.stream;

  @override
  List<PlayerState> get currentPlayers => _players.values.toList();

  @override
  String get localPlayerId => _localPlayerId;

  // Bot states for local AI simulation
  final Map<String, _BotData> _botMetadata = {};

  @override
  Future<void> connect({
    required String roomId,
    required String playerName,
    required int characterId,
    int botCount = 3, // Configurable bot count (up to 9 to reach 10 players)
  }) async {
    _localPlayerId = 'player_01';
    _localPlayerName = playerName;
    _localCharacterId = characterId;

    _players.clear();
    _botMetadata.clear();

    // Register local player
    _players[_localPlayerId] = PlayerState(
      playerId: _localPlayerId,
      characterId: _localCharacterId,
      name: _localPlayerName,
      x: 300,
      y: 800,
      health: 100,
      maxHealth: 100,
    );

    // Spawn mock players up to botCount
    // Each bot takes an unused character ID (1 to 10)
    final availableCharIds = List.generate(10, (i) => i + 1)
      ..remove(_localCharacterId);
    availableCharIds.shuffle(_rnd);

    final spawnPositions = [
      const Point(600.0, 800.0),
      const Point(1100.0, 700.0),
      const Point(1600.0, 800.0),
      const Point(850.0, 500.0),
      const Point(1400.0, 500.0),
      const Point(400.0, 350.0),
      const Point(1800.0, 350.0),
      const Point(1100.0, 250.0),
      const Point(200.0, 800.0),
    ];

    final clampedBots = min(botCount, 9);
    for (int i = 0; i < clampedBots; i++) {
      final botId = 'bot_${i + 1}';
      final charId = availableCharIds[i % availableCharIds.length];
      final spawn = spawnPositions[i % spawnPositions.length];

      final name = CharacterRegistry.getById(charId).name;

      _players[botId] = PlayerState(
        playerId: botId,
        characterId: charId,
        name: name,
        x: spawn.x.toDouble(),
        y: spawn.y.toDouble(),
        health: 100,
        maxHealth: 100,
      );

      _botMetadata[botId] = _BotData(
        direction: (i % 2 == 0) ? 1.0 : -1.0,
        patrolMinX: max(100.0, spawn.x - 250.0),
        patrolMaxX: min(2200.0, spawn.x + 250.0),
        shootCooldown: 1.0 + _rnd.nextDouble() * 2.0,
      );
    }

    _playersController.add(_players.values.toList());

    // Start simulation loop at 20 ticks per second (simulating 50ms network tick)
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _tickBots(0.05),
    );
  }

  void _tickBots(double dt) {
    bool changed = false;
    final localP = _players[_localPlayerId];

    for (final entry in _botMetadata.entries) {
      final botId = entry.key;
      final data = entry.value;
      final bot = _players[botId];
      if (bot == null) continue;

      if (bot.isDead) {
        data.respawnTimer -= dt;
        if (data.respawnTimer <= 0) {
          // Respawn
          final newX = 300.0 + _rnd.nextDouble() * 1600.0;
          final newY = 400.0 + _rnd.nextDouble() * 400.0;
          _players[botId] = bot.copyWith(
            health: bot.maxHealth,
            isDead: false,
            x: newX,
            y: newY,
            currentAnimation: 'idle',
          );
          data.respawnTimer = 3.0;
          changed = true;
        }
        continue;
      }

      // Patrol movement
      double x = bot.x + data.direction * 120 * dt;
      double y = bot.y;
      double dir = data.direction;
      if (x < data.patrolMinX) {
        x = data.patrolMinX;
        dir = 1.0;
      } else if (x > data.patrolMaxX) {
        x = data.patrolMaxX;
        dir = -1.0;
      }
      data.direction = dir;

      // Jetpack flight behavior for bots
      data.jetpackTimer -= dt;
      if (data.jetpackTimer <= -4.0 && _rnd.nextDouble() < 0.15) {
        data.jetpackTimer = 1.8; // Fly for 1.8 seconds
      }
      final isBotFlying = data.jetpackTimer > 0;
      if (isBotFlying) {
        y = max(350.0, y - 160 * dt);
      } else if (y < 800.0) {
        // Gravity descent back to platform
        y = min(800.0, y + 140 * dt);
      }

      // Aim towards nearest alive opponent (local player or another bot)
      double aim = 0.0;
      bool shooting = false;
      PlayerState? targetOpponent;
      double nearestDist = 650.0;

      // 1. Check local player
      if (localP != null && !localP.isDead) {
        final dx = localP.x - bot.x;
        final dy = localP.y - bot.y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < nearestDist) {
          nearestDist = dist;
          targetOpponent = localP;
        }
      }

      // 2. Also check other bots for FFA combat
      for (final other in _players.values) {
        if (other.playerId == botId ||
            other.playerId == _localPlayerId ||
            other.isDead) {
          continue;
        }
        final dx = other.x - bot.x;
        final dy = other.y - bot.y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < nearestDist) {
          nearestDist = dist;
          targetOpponent = other;
        }
      }

      if (targetOpponent != null) {
        final dx = targetOpponent.x - bot.x;
        final dy = targetOpponent.y - bot.y;
        aim = atan2(dy, dx);

        // Shoot at opponent when in range
        data.shootCooldown -= dt;
        if (data.shootCooldown <= 0) {
          data.shootCooldown = 1.2 + _rnd.nextDouble() * 1.5;
          shooting = true;

          // Dispatch simulated bullet
          _bulletController.add(
            BulletNetworkEvent(
              bulletId: 'b_${DateTime.now().microsecondsSinceEpoch}_$botId',
              shooterId: botId,
              startX: bot.x + (dx > 0 ? 20 : -20),
              startY: bot.y - 10,
              angle: aim + (_rnd.nextDouble() - 0.5) * 0.15,
              speed: 600,
              damage: 15,
            ),
          );
        }
      }

      _players[botId] = bot.copyWith(
        x: x,
        y: y,
        facingDirection: dir,
        aimAngle: aim,
        currentAnimation: isBotFlying ? 'jump' : 'run',
        isShooting: shooting,
        isFlying: isBotFlying,
        jetpackFuel: isBotFlying ? 60.0 : 100.0,
      );
      changed = true;
    }

    if (changed) {
      _playersController.add(_players.values.toList());
    }
  }

  @override
  void sendPlayerUpdate(PlayerState state) {
    _players[state.playerId] = state;
    _playersController.add(_players.values.toList());
  }

  @override
  void sendShootEvent(BulletNetworkEvent event) {
    _bulletController.add(event);
  }

  @override
  void sendDamageEvent({
    required String targetPlayerId,
    required double damage,
    required String attackerId,
  }) {
    final target = _players[targetPlayerId];
    if (target == null || target.isDead) return;

    final newHealth = max(0.0, target.health - damage);
    final isDead = newHealth <= 0.0;

    _players[targetPlayerId] = target.copyWith(
      health: newHealth,
      isDead: isDead,
      deaths: isDead ? target.deaths + 1 : target.deaths,
      currentAnimation: isDead ? 'death' : target.currentAnimation,
    );

    if (isDead) {
      final attacker = _players[attackerId];
      if (attacker != null) {
        _players[attackerId] = attacker.copyWith(kills: attacker.kills + 1);
      }
      if (_botMetadata.containsKey(targetPlayerId)) {
        _botMetadata[targetPlayerId]!.respawnTimer = 3.5;
      }
    }

    _playersController.add(_players.values.toList());
  }

  @override
  void disconnect() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _playersController.close();
    _bulletController.close();
  }
}

class _BotData {
  double direction;
  final double patrolMinX;
  final double patrolMaxX;
  double shootCooldown;
  double respawnTimer = 3.0;
  double jetpackTimer = -2.0;

  _BotData({
    required this.direction,
    required this.patrolMinX,
    required this.patrolMaxX,
    required this.shootCooldown,
  });
}
