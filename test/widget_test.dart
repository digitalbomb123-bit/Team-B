import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_b_shooter/main.dart';

void main() {
  testWidgets('Mini Militia App smoke test', (WidgetTester tester) async {
    // Set landscape viewport for landscape-first testing
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiniMilitiaApp());
    await tester.pumpAndSettle();

    expect(find.text('TEAM B'), findsOneWidget);
    expect(find.text('ENTER ARENA'), findsOneWidget);
  });
}
