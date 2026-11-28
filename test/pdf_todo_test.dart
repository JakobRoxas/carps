import 'package:carps/controllers/app_controller.dart';
import 'package:carps/core/widgets/carps_widgets.dart';
import 'package:carps/main.dart';
import 'package:carps/repositories/mock_carps_repository.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final now = DateTime(2026, 11, 24, 15);
  late AppController app;

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  Future<void> boot(WidgetTester tester, String userId) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    app = AppController(MockCarpsRepository.seeded(now), clock: () => now)
      ..signIn(userId);
    await tester.pumpWidget(CarpsApp(controller: app));
    await settle(tester);
  }

  void go(WidgetTester tester, String path) {
    final element = tester.element(find.byType(Scaffold).first);
    GoRouter.of(element).go(path);
  }

  testWidgets('Find People uses compact rows and navigates to a profile', (
    tester,
  ) async {
    await boot(tester, DemoIds.ana);
    go(tester, '/search');
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, 'Mika');
    await settle(tester);

    expect(find.text('Find People'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('person-${DemoIds.mika}')),
      findsOneWidget,
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('person-${DemoIds.mika}'))),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    await mouse.removePointer();

    final person = find.byKey(const ValueKey('person-${DemoIds.mika}'));
    await tester.ensureVisible(person);
    await settle(tester);
    await tester.tap(person);
    await settle(tester);
    expect(find.text('Mika Cruz'), findsWidgets);
  });

  testWidgets('Find People clears cleanly and shows no stale person', (
    tester,
  ) async {
    await boot(tester, DemoIds.ana);
    go(tester, '/search');
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, 'Mika');
    await settle(tester);
    expect(find.text('Find People'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '');
    await settle(tester);
    expect(find.text('Find People'), findsNothing);
  });

  testWidgets('roster separates scanner, tabs, and roster states', (
    tester,
  ) async {
    await boot(tester, DemoIds.mika);
    go(tester, '/event/${DemoIds.pickleballLive}/roster');
    await settle(tester);

    expect(find.text('Live check-in scanner'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
    expect(find.textContaining('Approved ('), findsOneWidget);
    expect(find.textContaining('Other ('), findsOneWidget);

    final scannerY = tester.getTopLeft(find.text('Live check-in scanner')).dy;
    final tabsY = tester.getTopLeft(find.text('Requests')).dy;
    expect(tabsY, greaterThan(scannerY));
    expect(tester.takeException(), isNull);
  });

  testWidgets('roster fills the viewport without a bottom layout gap', (
    tester,
  ) async {
    await boot(tester, DemoIds.mika);
    go(tester, '/event/${DemoIds.pickleballLive}/roster');
    await settle(tester);

    final darkSheets = find.byWidgetPredicate((widget) => widget is Container);
    expect(darkSheets, findsWidgets);

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final darkSheetBottom = tester
        .getBottomRight(find.byType(DarkSheet).first)
        .dy;
    expect(darkSheetBottom, closeTo(screenHeight, 2));
  });

  testWidgets('profile removes inactive bolt and explains visitor visibility', (
    tester,
  ) async {
    await boot(tester, DemoIds.ana);
    go(tester, '/profile');
    await settle(tester);

    expect(find.text('Privacy guard'), findsNothing);

    final switchVisitor = find.text('Switch to visitor');
    await tester.ensureVisible(switchVisitor);
    await settle(tester);
    await tester.tap(switchVisitor);
    await settle(tester);
    expect(
      find.textContaining('Showing only what a public visitor can see'),
      findsOneWidget,
    );
  });
}
