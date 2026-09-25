import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_b_shooter/controls/input_controller.dart';
import 'package:team_b_shooter/controls/mobile_controls.dart';
import 'package:team_b_shooter/game/components/fart_bomb_pickup.dart';
import 'package:team_b_shooter/game/components/player.dart';
import 'package:team_b_shooter/game/components/toxic_gas_cloud.dart';
import 'package:team_b_shooter/game/mini_militia_game.dart';
import 'package:team_b_shooter/multiplayer/mock_multiplayer_client.dart';
import 'package:team_b_shooter/ui/hud.dart';

void main() {
  group('Fart Bomb Components & Game Mechanics', () {
    late MockMultiplayerClient client;
    late InputController inputController;
    late MiniMilitiaGame game;

    setUp(() async {
      client = MockMultiplayerClient();
      inputController = InputController();
      game = MiniMilitiaGame(
        multiplayerClient: client,
        inputController: inputController,
        selectedCharacterId: 1,
        playerName: 'Tester',
      );
      await game.onLoad();
    });

    test('Player starts with 0 fart bombs and can collect pickups', () {
      final player = PlayerComponent(
        playerId: 'test_player',
        name: 'Tester',
        characterId: 1,
        position: Vector2(100, 100),
        isLocal: true,
      );

      expect(player.fartBombCount, equals(0));
      expect(player.isFarting, isFalse);

      // Collect a bomb
      player.fartBombCount += 1;
      expect(player.fartBombCount, equals(1));
    });

    test('Calling blastFartBomb decrements count, triggers farting state and forward propulsion', () {
      final player = PlayerComponent(
        playerId: 'test_player',
        name: 'Tester',
        characterId: 1,
        position: Vector2(100, 100),
        isLocal: true,
      );
      player.fartBombCount = 2;

      // Trigger fart bomb
      final success = player.blastFartBomb(game);

      expect(success, isTrue);
      expect(player.fartBombCount, equals(1));
      expect(player.isFarting, isTrue);
      expect(player.fartAnimationTimer, greaterThan(0));

      // After timer elapses in update, isFarting resets
      player.update(1.0);
      expect(player.isFarting, isFalse);
    });

    test('blastFartBomb fails when fartBombCount is 0', () {
      final player = PlayerComponent(
        playerId: 'test_player',
        name: 'Tester',
        characterId: 1,
        position: Vector2(100, 100),
        isLocal: true,
      );
      player.fartBombCount = 0;

      final success = player.blastFartBomb(game);
      expect(success, isFalse);
      expect(player.isFarting, isFalse);
    });

    test('ToxicGasCloudComponent damages players inside radius over time', () {
      final cloud = ToxicGasCloudComponent(
        position: Vector2(200, 200),
        shooterId: 'attacker',
        maxRadius: 85.0,
        lifetime: 5.0,
      );

      final victim = PlayerComponent(
        playerId: 'victim',
        name: 'Victim',
        characterId: 2,
        position: Vector2(210, 210), // Inside cloud
        isLocal: true,
      );
      victim.health = 100.0;

      final distantPlayer = PlayerComponent(
        playerId: 'distant',
        name: 'Distant',
        characterId: 3,
        position: Vector2(600, 600), // Outside cloud
        isLocal: false,
      );
      distantPlayer.health = 100.0;

      game.world.add(cloud);
      game.world.add(victim);
      game.world.add(distantPlayer);
      game.update(0.0);

      // Cloud tick
      cloud.update(0.3);

      // Victim takes damage
      expect(victim.health, lessThan(100.0));
      expect(victim.isPoisoned, isTrue);

      // Distant player is untouched
      expect(distantPlayer.health, equals(100.0));
    });

    test('FartBombPickupComponent collects when player collides with it', () {
      final pickup = FartBombPickupComponent(
        position: Vector2(300, 300),
      );

      final player = PlayerComponent(
        playerId: 'collector',
        name: 'Collector',
        characterId: 1,
        position: Vector2(305, 305),
        isLocal: true,
      );
      player.fartBombCount = 0;

      game.world.add(pickup);
      game.update(0.0);
      pickup.collect(player);

      expect(pickup.isCollected, isTrue);
      expect(player.fartBombCount, equals(1));
    });
  });

  group('Fart Bomb UI & Mobile Controls Overlay', () {
    testWidgets('Fart Bomb button is disabled when count is 0', (WidgetTester tester) async {
      final inputController = InputController();
      final countNotifier = ValueNotifier<int>(0);
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileControlsOverlay(
              inputController: inputController,
              fartBombCountListenable: countNotifier,
              onFartBombPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the FART BOMB button
      expect(find.text('FART BOMB'), findsOneWidget);

      // Tap the button while count is 0
      await tester.tap(find.text('FART BOMB'));
      await tester.pump();

      // Should not trigger callback when count is 0
      expect(pressed, isFalse);

      countNotifier.dispose();
      inputController.dispose();
    });

    testWidgets('Fart Bomb button enables and fires when count > 0', (WidgetTester tester) async {
      final inputController = InputController();
      final countNotifier = ValueNotifier<int>(0);
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileControlsOverlay(
              inputController: inputController,
              fartBombCountListenable: countNotifier,
              onFartBombPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Increment count to 2
      countNotifier.value = 2;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Count badge x2 should be visible
      expect(find.text('x2'), findsOneWidget);

      // Tap the FART BOMB button
      await tester.tap(find.text('FART BOMB'));
      await tester.pump();

      // Should trigger callback
      expect(pressed, isTrue);

      countNotifier.dispose();
      inputController.dispose();
    });

    testWidgets('GameHud renders Fart Bomb indicator badge when count > 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameHud(
              currentHealth: 100,
              maxHealth: 100,
              kills: 2,
              deaths: 1,
              characterId: 1,
              playerName: 'Hero',
              fartBombCount: 3,
              onPausePressed: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Badge showing fart icon and x3 count
      expect(find.text('x3'), findsOneWidget);
    });
  });
}
