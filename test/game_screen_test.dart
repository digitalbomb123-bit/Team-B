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
}
