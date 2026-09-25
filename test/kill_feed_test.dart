import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_b_shooter/controls/input_controller.dart';
import 'package:team_b_shooter/game/components/player.dart';
import 'package:team_b_shooter/game/mini_militia_game.dart';
import 'package:team_b_shooter/multiplayer/mock_multiplayer_client.dart';
import 'package:team_b_shooter/multiplayer/player_state.dart';
import 'package:team_b_shooter/ui/kill_feed_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KillFeedOverlay Widget Tests', () {
    testWidgets('renders killer and victim text with bullet elimination', (tester) async {
      final notifier = ValueNotifier<List<KillFeedEntry>>([
        KillFeedEntry(
          id: '1',
          killerName: 'Major Kelly',
          victimName: 'Sgt. Rock',
          weapon: 'bullet',
          isLocalKiller: false,
          isLocalVictim: false,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KillFeedOverlay(killFeedListenable: notifier),
          ),
        ),
      );

      expect(find.text('Major Kelly'), findsOneWidget);
      expect(find.text('Sgt. Rock'), findsOneWidget);
      expect(find.text('eliminated'), findsOneWidget);
      expect(find.text('🎯'), findsOneWidget);
    });

    testWidgets('renders YOU when local player is the killer', (tester) async {
      final notifier = ValueNotifier<List<KillFeedEntry>>([
        KillFeedEntry(
          id: '2',
          killerName: 'Commander Alex',
          victimName: 'Ghost',
          weapon: 'fart_bomb',
          isLocalKiller: true,
          isLocalVictim: false,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KillFeedOverlay(killFeedListenable: notifier),
          ),
        ),
      );

      expect(find.text('YOU'), findsOneWidget);
      expect(find.text('Ghost'), findsOneWidget);
      expect(find.text('fart-bombed'), findsOneWidget);
      expect(find.text('💨'), findsOneWidget);
    });

    testWidgets('renders YOU when local player is the victim', (tester) async {
      final notifier = ValueNotifier<List<KillFeedEntry>>([
        KillFeedEntry(
          id: '3',
          killerName: 'Viper',
          victimName: 'Commander Alex',
          weapon: 'bullet',
          isLocalKiller: false,
          isLocalVictim: true,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KillFeedOverlay(killFeedListenable: notifier),
          ),
        ),
      );

      expect(find.text('Viper'), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget);
      expect(find.text('eliminated'), findsOneWidget);
      expect(find.text('🎯'), findsOneWidget);
    });
  });

  group('MiniMilitiaGame Kill Attribution Tests', () {
    test('Player taking lethal damage sets killer and triggers onDeath', () {
      final player = PlayerComponent(
        playerId: 'p1',
        characterId: 0,
        name: 'TargetPlayer',
        position: Vector2(100, 100),
        isLocal: false,
      );

      bool deathCallbackCalled = false;
      player.onDeath = (p) {
        deathCallbackCalled = true;
      };

      player.takeDamage(100.0, attackerId: 'p2', attackerName: 'Sniper', weapon: 'bullet');

      expect(player.isDead, isTrue);
      expect(deathCallbackCalled, isTrue);
      expect(player.lastAttackerId, equals('p2'));
      expect(player.lastAttackerName, equals('Sniper'));
      expect(player.lastAttackerWeapon, equals('bullet'));
    });

    test('Fart bomb lethal damage tracks fart_bomb weapon type', () {
      final player = PlayerComponent(
        playerId: 'victim_1',
        characterId: 1,
        name: 'UnluckyBot',
        position: Vector2(100, 100),
        isLocal: false,
      );

      player.takeDamage(100.0, attackerId: 'killer_1', attackerName: 'GasMaster', weapon: 'fart_bomb');

      expect(player.isDead, isTrue);
      expect(player.lastAttackerId, equals('killer_1'));
      expect(player.lastAttackerName, equals('GasMaster'));
      expect(player.lastAttackerWeapon, equals('fart_bomb'));
    });

    test('Game dispatches onKillFeedEvent when player dies', () async {
      final mockClient = MockMultiplayerClient();
      final inputController = InputController();

      final game = MiniMilitiaGame(
        multiplayerClient: mockClient,
        inputController: inputController,
        selectedCharacterId: 0,
        playerName: 'LocalHero',
      );

      String? recordedKiller;
      String? recordedVictim;
      String? recordedWeapon;
      bool? recordedIsLocalVictim;

      game.onKillFeedEvent = ({
        required String killerName,
        required String victimName,
        required String weapon,
        required bool isLocalKiller,
        required bool isLocalVictim,
      }) {
        recordedKiller = killerName;
        recordedVictim = victimName;
        recordedWeapon = weapon;
        recordedIsLocalVictim = isLocalVictim;
      };

      await game.onLoad();

      // Damage local player to death with attacker info
      game.localPlayer.takeDamage(100.0, attackerId: 'bot_99', attackerName: 'RogueBot', weapon: 'bullet');

      expect(recordedKiller, equals('RogueBot'));
      expect(recordedVictim, equals('LocalHero'));
      expect(recordedWeapon, equals('bullet'));
      expect(recordedIsLocalVictim, isTrue);
      expect(game.deaths, equals(1));
    });
  });
}
