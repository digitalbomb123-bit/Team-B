import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_b_shooter/main.dart';

void main() {
  testWidgets('Test entering arena and rendering GameScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiniMilitiaApp());
    await tester.pumpAndSettle();

    // Click ENTER ARENA
    final enterButton = find.text('ENTER ARENA');
    expect(enterButton, findsOneWidget);
    await tester.tap(enterButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify HUD & Dual Joystick elements are rendered
    expect(find.text('Soldier'), findsWidgets);
    expect(find.text('JETPACK'), findsOneWidget);
    expect(find.text('AIM & FIRE'), findsOneWidget);
    expect(find.text('MOVE / FLY'), findsOneWidget);

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

    // Tap ENTER ARENA
    await tester.tap(enterButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Cleanup
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
