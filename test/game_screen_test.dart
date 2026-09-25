import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_b_shooter/main.dart';
import 'package:team_b_shooter/screens/game_screen.dart';
import 'package:team_b_shooter/screens/room_waiting_screen.dart';
import 'package:team_b_shooter/ui/scoreboard_dialog.dart';

void main() {
  testWidgets('Test entering 15s waiting lobby, countdown, and GameScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiniMilitiaApp());
    await tester.pumpAndSettle();

    // Verify Game Time setter in Lobby
    expect(find.text('GAME TIME:'), findsOneWidget);
    expect(find.text('⏱ 03:00 (3 min)'), findsOneWidget);

    // Switch Game Time to 5m
    final fiveMinButton = find.text('5m');
    expect(fiveMinButton, findsOneWidget);
    await tester.tap(fiveMinButton);
    await tester.pumpAndSettle();
    expect(find.text('⏱ 05:00 (5 min)'), findsOneWidget);

    // Click ENTER ARENA
    final enterButton = find.text('ENTER ARENA');
    expect(enterButton, findsOneWidget);
    await tester.tap(enterButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify 15-second Room Waiting Lobby is rendered
    expect(find.byType(RoomWaitingScreen), findsOneWidget);
    expect(find.text('MATCH STARTS IN'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('MATCH TIME: 05:00'), findsOneWidget);
    expect(find.text('START NOW'), findsOneWidget);

    // Tap START NOW to enter GameScreen immediately
    await tester.tap(find.text('START NOW'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify HUD & Dual Joystick elements are rendered
    expect(find.text('Nandhu'), findsWidgets);
    expect(find.text('FART BOMB'), findsOneWidget);
    expect(find.text('AIM & FIRE'), findsOneWidget);
    expect(find.text('MOVE / FLY'), findsOneWidget);
    // Verify match timer clock is rendered in HUD
    expect(find.text('05:00'), findsOneWidget);

    // Unmount to cancel any active game timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Test LobbyScreen on small mobile landscape screen (667x340)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(667, 340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiniMilitiaApp());
    await tester.pumpAndSettle();

    // Verify ENTER ARENA is visible and can be tapped without overflow
    final enterButton = find.text('ENTER ARENA');
    expect(enterButton, findsOneWidget);

    // Verify scrollability of left panel
    final scrollView = find.byType(SingleChildScrollView);
    expect(scrollView, findsOneWidget);
    await tester.drag(scrollView, const Offset(0, -30));
    await tester.pumpAndSettle();

    // Switch to MULTIPLAYER mode
    final multiplayerTab = find.text('MULTIPLAYER');
    expect(multiplayerTab, findsOneWidget);
    await tester.tap(multiplayerTab);
    await tester.pumpAndSettle();

    // Verify JOIN ONLINE ARENA is visible and pinned at bottom
    final joinButton = find.text('JOIN ONLINE ARENA');
    expect(joinButton, findsOneWidget);

    // Switch back to SOLO BOTS
    final soloTab = find.text('SOLO BOTS');
    expect(soloTab, findsOneWidget);
    await tester.tap(soloTab);
    await tester.pumpAndSettle();

    // Tap ENTER ARENA to enter waiting lobby
    await tester.tap(enterButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify waiting lobby
    expect(find.byType(RoomWaitingScreen), findsOneWidget);
    final startNow = find.text('START NOW');
    expect(startNow, findsOneWidget);
    await tester.tap(startNow);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Cleanup
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Firing is only done by Aim Joystick, screen tap does not trigger fire', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiniMilitiaApp());
    await tester.pumpAndSettle();

    // Enter Arena -> Waiting Room -> GameScreen
    await tester.tap(find.text('ENTER ARENA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('START NOW'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap in the middle of the screen
    await tester.tapAt(const Offset(640, 360));
    await tester.pump();

    // Verify shooting is NOT triggered by screen tap
    final gameScreenState = tester.state(find.byType(GameScreen)) as dynamic;
    expect(gameScreenState.inputController.isShooting, isFalse);

    // Now drag the Aim Joystick (found by 'AIM & FIRE' label)
    final aimLabel = find.text('AIM & FIRE');
    expect(aimLabel, findsOneWidget);
    final aimCenter = tester.getCenter(aimLabel) - const Offset(0, 40);
    final gesture = await tester.startGesture(aimCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(35, 0));
    await tester.pump();

    // Verify dragging aim joystick activates shooting
    expect(gameScreenState.inputController.isShooting, isTrue);

    // Release joystick
    await gesture.up();
    await tester.pump();

    // Verify releasing stops shooting
    expect(gameScreenState.inputController.isShooting, isFalse);

    // Cleanup
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('ScoreboardDialog renders all players and their kills correctly', (WidgetTester tester) async {
    final testScores = [
      const MatchPlayerScore(
        playerId: 'p1',
        name: 'Hero',
        characterId: 1,
        kills: 3,
        deaths: 1,
        isLocal: true,
      ),
      const MatchPlayerScore(
        playerId: 'p2',
        name: 'Nandhu',
        characterId: 2,
        kills: 6,
        deaths: 2,
        isLocal: false,
      ),
      const MatchPlayerScore(
        playerId: 'p3',
        name: 'Shadow',
        characterId: 3,
        kills: 1,
        deaths: 4,
        isLocal: false,
      ),
      const MatchPlayerScore(
        playerId: 'p4',
        name: 'Viper',
        characterId: 4,
        kills: 0,
        deaths: 3,
        isLocal: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScoreboardDialog(
            scores: testScores,
            isMatchOver: true,
            matchDurationSeconds: 180,
            onPlayAgain: () {},
            onMainMenu: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Header
    expect(find.text('MATCH SCOREBOARD'), findsOneWidget);
    expect(find.text('MATCH MVP: Nandhu (6 KILLS)'), findsOneWidget);

    // Verify Table Headers
    expect(find.text('RANK'), findsOneWidget);
    expect(find.text('COMBATANT'), findsOneWidget);
    expect(find.text('KILLS'), findsOneWidget);
    expect(find.text('DEATHS'), findsOneWidget);
    expect(find.text('K/D'), findsOneWidget);

    // Verify all players are listed
    expect(find.text('Nandhu'), findsOneWidget);
    expect(find.text('Hero'), findsOneWidget);
    expect(find.text('Shadow'), findsOneWidget);
    expect(find.text('Viper'), findsOneWidget);

    // Verify local player has YOU badge
    expect(find.text('YOU'), findsOneWidget);

    // Verify kill numbers
    expect(find.text('6'), findsOneWidget);
    expect(find.text('3'), findsAtLeastNWidgets(1));
    expect(find.text('1'), findsAtLeastNWidgets(1));
    expect(find.text('0'), findsAtLeastNWidgets(1));

    // Verify action buttons
    expect(find.text('PLAY AGAIN'), findsOneWidget);
    expect(find.text('MAIN MENU'), findsOneWidget);
  });

  testWidgets('Tapping HUD score badge opens live scoreboard during match', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiniMilitiaApp());
    await tester.pumpAndSettle();

    // Launch match
    await tester.tap(find.text('ENTER ARENA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('START NOW'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap on the kills/score badge in the HUD
    final scoreBadgeIcon = find.byIcon(Icons.gps_fixed_rounded);
    expect(scoreBadgeIcon, findsWidgets);
    await tester.tap(scoreBadgeIcon.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify live scoreboard dialog opens
    expect(find.byType(ScoreboardDialog), findsOneWidget);
    expect(find.text('LIVE ARENA SCOREBOARD'), findsOneWidget);
    expect(find.text('RESUME'), findsOneWidget);

    // Tap RESUME to close
    await tester.tap(find.text('RESUME'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ScoreboardDialog), findsNothing);

    // Cleanup
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
