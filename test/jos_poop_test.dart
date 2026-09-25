import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_b_shooter/characters/character_registry.dart';
import 'package:team_b_shooter/controls/input_controller.dart';
import 'package:team_b_shooter/controls/mobile_controls.dart';
import 'package:team_b_shooter/game/components/player.dart';
import 'package:team_b_shooter/game/components/poop_trap.dart';
import 'package:team_b_shooter/game/mini_militia_game.dart';
import 'package:team_b_shooter/multiplayer/mock_multiplayer_client.dart';

void main() {
  group('Jos Avatar Exclusive Poop Power Tests', () {
    late MockMultiplayerClient client;
    late InputController inputController;
    late MiniMilitiaGame game;

    setUp(() async {
      client = MockMultiplayerClient();
      inputController = InputController();
      game = MiniMilitiaGame(
        multiplayerClient: client,
        inputController: inputController,
        selectedCharacterId: 5, // Jos
        playerName: 'Jos',
      );
      await game.onLoad();
    });

    test('Jos character definition (ID 5) has exclusive poop trap description', () {
      final josDef = CharacterRegistry.characters.firstWhere((c) => c.id == 5);
      expect(josDef.name, 'Jos');
      expect(josDef.description.toLowerCase(), contains('poop'));
    });

    test('Only Jos avatar has isJos exception flag', () {
      final jos = PlayerComponent(
        playerId: 'jos_player',
        name: 'Jos',
        characterId: 5,
        position: Vector2(100, 100),
        isLocal: true,
      );
      final nandhu = PlayerComponent(
        playerId: 'nandhu_player',
        name: 'Nandhu',
        characterId: 1,
        position: Vector2(100, 100),
        isLocal: false,
      );

      expect(jos.isJos, isTrue);
      expect(nandhu.isJos, isFalse);
    });

    test('Jos can drop poop, which adds PoopTrapComponent to arena and starts cooldown', () {
      final jos = game.localPlayer;
      expect(jos.isJos, isTrue);
      expect(jos.canPoop, isTrue);

      final dropped = jos.dropPoop(game);
      expect(dropped, isTrue);
      expect(jos.canPoop, isFalse);
      expect(jos.poopCooldownTimer, greaterThan(0));

      final traps = game.world.children.whereType<PoopTrapComponent>().toList();
      expect(traps.length, 1);
      expect(traps.first.ownerId, jos.playerId);
    });

    test('Non-Jos characters cannot drop poop', () {
      final soldier = PlayerComponent(
        playerId: 'soldier_1',
        name: 'Albin',
        characterId: 2,
        position: Vector2(200, 200),
      );
      expect(soldier.isJos, isFalse);
      expect(soldier.canPoop, isFalse);
      expect(soldier.dropPoop(game), isFalse);
    });

    test('When enemy touches poop trap, enemy gets stuck and immobilized', () {
      final jos = game.localPlayer;
      final enemy = PlayerComponent(
        playerId: 'enemy_bot',
        name: 'Enemy',
        characterId: 3,
        position: Vector2(400, 950),
        isLocal: false,
      );
      game.world.add(enemy);

      final trap = PoopTrapComponent(
        position: Vector2(400, 950),
        ownerId: jos.playerId,
        ownerName: 'Jos',
        stuckDuration: 3.5,
      );
      game.world.add(trap);

      expect(enemy.isStuck, isFalse);

      // Advance component update
      trap.update(0.016);

      // Enemy stepped in poop!
      expect(enemy.isStuck, isTrue);
      expect(enemy.stuckTimer, greaterThan(0));
      expect(trap.isTriggered, isTrue);

      // While stuck, enemy cannot move or jump
      enemy.move(1.0);
      expect(enemy.velocity.x, 0.0);

      enemy.isGrounded = true;
      enemy.jump();
      expect(enemy.isFlying, isFalse);
    });

    test('Jos (owner) does NOT get stuck when touching his own poop', () {
      final jos = game.localPlayer;
      jos.position = Vector2(500, 950);

      final trap = PoopTrapComponent(
        position: Vector2(500, 950),
        ownerId: jos.playerId,
        ownerName: 'Jos',
        stuckDuration: 3.5,
      );
      game.world.add(trap);

      trap.update(0.016);

      // Jos is unaffected by his own poop
      expect(jos.isStuck, isFalse);
      expect(trap.isTriggered, isFalse);
    });

    testWidgets('MobileControlsOverlay renders POOP button for Jos (characterId 5)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileControlsOverlay(
              inputController: inputController,
              selectedCharacterId: 5, // Jos
              poopCooldownListenable: ValueNotifier<double>(0.0),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('POOP'), findsOneWidget);
      expect(find.text('💩'), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
    });

    testWidgets('MobileControlsOverlay renders FART BOMB for other avatars (characterId != 5)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileControlsOverlay(
              inputController: inputController,
              selectedCharacterId: 1, // Nandhu
              fartBombCountListenable: ValueNotifier<int>(0),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('FART BOMB'), findsOneWidget);
      expect(find.text('POOP'), findsNothing);
    });
  });
}
