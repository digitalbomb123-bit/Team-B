import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_b_shooter/multiplayer/player_state.dart';

void main() {
  group('Multiplayer Protocol Tests', () {
    test('PlayerState serialization and deserialization', () {
      const original = PlayerState(
        playerId: 'p_12345',
        characterId: 3,
        name: 'Ghost',
        x: 450.5,
        y: 120.0,
        vx: 120.0,
        vy: -200.0,
        facingDirection: -1.0,
        aimAngle: 2.35,
        currentAnimation: 'run',
        isShooting: true,
        isFlying: true,
        jetpackFuel: 75.5,
        health: 80.0,
        maxHealth: 100.0,
        isDead: false,
        kills: 3,
        deaths: 1,
      );

      final map = original.toMap();
      final jsonStr = jsonEncode(map);
      final decodedMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = PlayerState.fromMap(decodedMap);

      expect(restored.playerId, equals('p_12345'));
      expect(restored.characterId, equals(3));
      expect(restored.name, equals('Ghost'));
      expect(restored.x, equals(450.5));
      expect(restored.y, equals(120.0));
      expect(restored.isFlying, isTrue);
      expect(restored.jetpackFuel, equals(75.5));
      expect(restored.kills, equals(3));
    });

    test('BulletNetworkEvent serialization and deserialization', () {
      const event = BulletNetworkEvent(
        bulletId: 'b_999_p1',
        shooterId: 'p_1',
        startX: 100.0,
        startY: 200.0,
        angle: 1.57,
        speed: 850.0,
        damage: 25.0,
      );

      final map = event.toMap();
      final jsonStr = jsonEncode(map);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = BulletNetworkEvent.fromMap(decoded);

      expect(restored.bulletId, equals('b_999_p1'));
      expect(restored.shooterId, equals('p_1'));
      expect(restored.damage, equals(25.0));
      expect(restored.speed, equals(850.0));
    });
  });
}
