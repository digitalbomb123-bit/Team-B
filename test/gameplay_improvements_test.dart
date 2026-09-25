import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_b_shooter/game/components/jetpack_fuel_pickup.dart';
import 'package:team_b_shooter/game/components/player.dart';
import 'package:team_b_shooter/main.dart';
import 'package:team_b_shooter/ui/health_bar.dart';
import 'package:team_b_shooter/ui/hud.dart';

void main() {
  group('Additional Jetpack Fuel Mechanics', () {
    test('JetpackFuelPickupComponent grants 10s super fuel to player', () {
      final player = PlayerComponent(
        playerId: 'p1',
        name: 'Tester',
        characterId: 1,
        position: Vector2(100, 100),
        isLocal: true,
      );

      expect(player.superFuelTimer, equals(0.0));
      expect(player.hasSuperFuel, isFalse);

      final pickup = JetpackFuelPickupComponent(
        position: Vector2(105, 105),
      );

      pickup.collect(player);

      expect(pickup.isCollected, isTrue);
      expect(player.superFuelTimer, equals(10.0));
      expect(player.hasSuperFuel, isTrue);
    });

    test('Flying burns super fuel before burning standard fuel', () {
      final player = PlayerComponent(
        playerId: 'p1',
        name: 'Tester',
        characterId: 1,
        position: Vector2(100, 100),
        isLocal: true,
      );
      player.jetpackFuel = 100.0;
      player.applySuperFuel(10.0);

      // Start flying
      player.setFlying(true);
      expect(player.isFlying, isTrue);

      // Simulate 2 seconds of flight
      player.update(2.0);

      // Super fuel timer decreased by 2s (~8s left)
      expect(player.superFuelTimer, closeTo(8.0, 0.01));
      // Base fuel is preserved at 100.0
      expect(player.jetpackFuel, equals(100.0));
    });
  });

  group('HUD & UI Refinements', () {
    testWidgets('HudHealthBar renders visual bar without numeric text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HudHealthBar(
              currentHealth: 75,
              maxHealth: 100,
            ),
          ),
        ),
      );
      await tester.pump();

      // No '75 / 100' or numeric text should be present
      expect(find.text('75 / 100'), findsNothing);
      expect(find.text('75'), findsNothing);
    });

    testWidgets('GameHud shows timer and kill count at top right, hides own deaths', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameHud(
              currentHealth: 100,
              maxHealth: 100,
              kills: 7,
              deaths: 3,
              characterId: 1,
              playerName: 'Soldier',
              remainingSeconds: 120,
              onPausePressed: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Kill count is shown
      expect(find.text('7'), findsOneWidget);
      // Timer is shown (02:00)
      expect(find.text('02:00'), findsOneWidget);
      // Own death count (3) is NOT shown in top HUD
      expect(find.text('3'), findsNothing);
    });

    testWidgets('Lobby uses selected avatar name automatically without callsign text field', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MiniMilitiaApp());
      await tester.pumpAndSettle();

      // No TextField for callsign
      expect(find.byType(TextField), findsNothing);

      // Default avatar name 'Nandhu' is shown as combatant
      expect(find.byIcon(Icons.person_pin_rounded), findsOneWidget);
      expect(find.text('Nandhu'), findsWidgets);

      // Select Avatar 2 (Albin)
      final albinAvatarCard = find.text('Albin');
      expect(albinAvatarCard, findsWidgets);
      await tester.tap(albinAvatarCard.first);
      await tester.pumpAndSettle();

      // Combatant name updates automatically to Albin
      expect(find.text('Albin'), findsWidgets);
    });
  });
}
