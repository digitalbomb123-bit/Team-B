/// Represents the synchronized state of a player in the arena.
/// Designed for future WebSocket serialization (JSON/binary).
class PlayerState {
  final String playerId;
  final int characterId;
  final String name;
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double facingDirection; // 1.0 = right, -1.0 = left
  final double aimAngle; // Radians
  final String currentAnimation; // idle, run, jump, fall, shoot, death
  final bool isShooting;
  final bool isFlying;
  final double jetpackFuel;
  final double health;
  final double maxHealth;
  final bool isDead;
  final int kills;
  final int deaths;

  const PlayerState({
    required this.playerId,
    required this.characterId,
    required this.name,
    required this.x,
    required this.y,
    this.vx = 0.0,
    this.vy = 0.0,
    this.facingDirection = 1.0,
    this.aimAngle = 0.0,
    this.currentAnimation = 'idle',
    this.isShooting = false,
    this.isFlying = false,
    this.jetpackFuel = 100.0,
    this.health = 100.0,
    this.maxHealth = 100.0,
    this.isDead = false,
    this.kills = 0,
    this.deaths = 0,
  });

  PlayerState copyWith({
    String? playerId,
    int? characterId,
    String? name,
    double? x,
    double? y,
    double? vx,
    double? vy,
    double? facingDirection,
    double? aimAngle,
    String? currentAnimation,
    bool? isShooting,
    bool? isFlying,
    double? jetpackFuel,
    double? health,
    double? maxHealth,
    bool? isDead,
    int? kills,
    int? deaths,
  }) {
    return PlayerState(
      playerId: playerId ?? this.playerId,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      vx: vx ?? this.vx,
      vy: vy ?? this.vy,
      facingDirection: facingDirection ?? this.facingDirection,
      aimAngle: aimAngle ?? this.aimAngle,
      currentAnimation: currentAnimation ?? this.currentAnimation,
      isShooting: isShooting ?? this.isShooting,
      isFlying: isFlying ?? this.isFlying,
      jetpackFuel: jetpackFuel ?? this.jetpackFuel,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      isDead: isDead ?? this.isDead,
      kills: kills ?? this.kills,
      deaths: deaths ?? this.deaths,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'characterId': characterId,
      'name': name,
      'x': x,
      'y': y,
      'vx': vx,
      'vy': vy,
      'facingDirection': facingDirection,
      'aimAngle': aimAngle,
      'currentAnimation': currentAnimation,
      'isShooting': isShooting,
      'isFlying': isFlying,
      'jetpackFuel': jetpackFuel,
      'health': health,
      'maxHealth': maxHealth,
      'isDead': isDead,
      'kills': kills,
      'deaths': deaths,
    };
  }

  factory PlayerState.fromMap(Map<String, dynamic> map) {
    return PlayerState(
      playerId: map['playerId'] as String? ?? 'unknown',
      characterId: (map['characterId'] as num?)?.toInt() ?? 1,
      name: map['name'] as String? ?? 'Player',
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      vx: (map['vx'] as num?)?.toDouble() ?? 0.0,
      vy: (map['vy'] as num?)?.toDouble() ?? 0.0,
      facingDirection: (map['facingDirection'] as num?)?.toDouble() ?? 1.0,
      aimAngle: (map['aimAngle'] as num?)?.toDouble() ?? 0.0,
      currentAnimation: map['currentAnimation'] as String? ?? 'idle',
      isShooting: map['isShooting'] as bool? ?? false,
      isFlying: map['isFlying'] as bool? ?? false,
      jetpackFuel: (map['jetpackFuel'] as num?)?.toDouble() ?? 100.0,
      health: (map['health'] as num?)?.toDouble() ?? 100.0,
      maxHealth: (map['maxHealth'] as num?)?.toDouble() ?? 100.0,
      isDead: map['isDead'] as bool? ?? false,
      kills: (map['kills'] as num?)?.toInt() ?? 0,
      deaths: (map['deaths'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Event representing a fired bullet for network replication.
class BulletNetworkEvent {
  final String bulletId;
  final String shooterId;
  final double startX;
  final double startY;
  final double angle;
  final double speed;
  final double damage;

  const BulletNetworkEvent({
    required this.bulletId,
    required this.shooterId,
    required this.startX,
    required this.startY,
    required this.angle,
    required this.speed,
    required this.damage,
  });

  Map<String, dynamic> toMap() => {
        'bulletId': bulletId,
        'shooterId': shooterId,
        'startX': startX,
        'startY': startY,
        'angle': angle,
        'speed': speed,
        'damage': damage,
      };

  factory BulletNetworkEvent.fromMap(Map<String, dynamic> map) =>
      BulletNetworkEvent(
        bulletId: map['bulletId'] as String,
        shooterId: map['shooterId'] as String,
        startX: (map['startX'] as num).toDouble(),
        startY: (map['startY'] as num).toDouble(),
        angle: (map['angle'] as num).toDouble(),
        speed: (map['speed'] as num).toDouble(),
        damage: (map['damage'] as num).toDouble(),
      );
}
