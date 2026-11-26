import 'package:carps/controllers/app_controller.dart';
import 'package:carps/core/theme/carps_colors.dart';
import 'package:carps/core/widgets/carps_widgets.dart';
import 'package:carps/main.dart';
import 'package:carps/models/carps_models.dart';
import 'package:carps/repositories/mock_carps_repository.dart';
import 'package:carps/views/profile/rsvps_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Drives the definition-of-done journey through the real widgets at phone
/// size: request → approve → pass → scan → end → tagged post, plus the
/// privacy and no-show negative paths.
void main() {
  late AppController app;
  final now = DateTime(2026, 11, 24, 15);

  /// pumpAndSettle doesn't wait for timers, so pump past the simulated
  /// network/latency delays first.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(); // build first so timers get scheduled
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    app = AppController(MockCarpsRepository.seeded(now), clock: () => now);
    await tester.pumpWidget(CarpsApp(controller: app));
    await settle(tester);
  }

  void go(WidgetTester tester, String path) {
    final el = tester.element(find.byType(Scaffold).first);
    ScaffoldMessenger.of(el).clearSnackBars();
    GoRouter.of(el).go(path);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text);
    if (f.evaluate().isEmpty) {
      // Lazily built list (e.g. the demo sheet): scroll until it exists.
      await tester.scrollUntilVisible(f, 200,
          scrollable: find.byType(Scrollable).last);
    }
    await tester.ensureVisible(f.first);
    await settle(tester);
    await tester.tap(f.first);
    await settle(tester);
  }

  final loginLogo = find.byWidgetPredicate(
    (widget) => widget is Image && widget.semanticLabel == 'CARPS koi ring logo',
  );
  final spinningLogo = find.ancestor(
    of: loginLogo,
    matching: find.byType(TweenAnimationBuilder<double>),
  );

  testWidgets('login ring makes one turn and stops', (tester) async {
    app = AppController(MockCarpsRepository.seeded(now), clock: () => now);
    await tester.pumpWidget(CarpsApp(controller: app));
    final transform = find.ancestor(of: loginLogo, matching: find.byType(Transform));
    final start = tester.widget<Transform>(transform.first).transform.clone();
    expect(spinningLogo, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.widget<Transform>(transform.first).transform, isNot(start));
    await settle(tester);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('login ring is visible without rotation with reduced motion',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await boot(tester);
    expect(loginLogo, findsOneWidget);
    expect(spinningLogo, findsNothing);
  });

  testWidgets('login with email lands a returning user on Home', (tester) async {
    await boot(tester);
    expect(find.text('Continue with Google'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'anareyes@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'carps123');
    await tester.tap(find.text('Log in').last);
    await settle(tester);
    expect(find.textContaining('Ana'), findsWidgets);
    expect(find.text('For You'), findsOneWidget);
    expect(find.text('Hosting'), findsOneWidget);
  });

  testWidgets('wrong password shows an error and stays on login', (tester) async {
    await boot(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'anareyes@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'nope-nope');
    await tester.tap(find.text('Log in').last);
    await settle(tester);
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('new sign-up goes through onboarding (no admin option)',
      (tester) async {
    await boot(tester);
    await tapText(tester, 'Sign up');
    await tester.enterText(find.byType(TextFormField).at(0), 'newbie@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'longpassword');
    await tester.tap(find.text('Create account'));
    await settle(tester);
    expect(find.text('Welcome to CARPS'), findsOneWidget);
    // Continue is disabled until the terms are accepted.
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Welcome to CARPS'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await settle(tester);
    await tapText(tester, 'Continue');
    expect(find.text('Choose your role'), findsOneWidget);
    expect(find.textContaining('Admin'), findsNothing);
  });

  testWidgets('definition of done through the UI', (tester) async {
    await boot(tester);
    const live = DemoIds.pickleballLive;

    // 1 · Ana requests admission.
    app.signIn(DemoIds.ana);
    await settle(tester);
    go(tester, '/event/$live');
    await settle(tester);
    await tapText(tester, 'Request to join');
    await tapText(tester, 'Send request');
    expect(find.text('Pending approval'), findsOneWidget);
    expect(app.service.passFor(live, DemoIds.ana), isNull);

    // 2 · Mika approves Ana from the roster.
    app.signIn(DemoIds.mika);
    await settle(tester);
    go(tester, '/event/$live/roster');
    await settle(tester);
    final approve = find.descendant(
        of: find.byKey(const ValueKey('request-${DemoIds.ana}')),
        matching: find.text('Approve'));
    await tester.ensureVisible(approve);
    await tester.tap(approve);
    await settle(tester);
    expect(app.service.registrationFor(live, DemoIds.ana)!.status,
        RegistrationStatus.approved);

    // 3 · Ana sees the pass.
    app.signIn(DemoIds.ana);
    await settle(tester);
    go(tester, '/pass/$live');
    await settle(tester);
    final token = app.service.passFor(live, DemoIds.ana)!.token;
    expect(find.text(token), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);

    // 4 · Mika scans Ana (and Sofia) at the venue; a repeat scan isn't counted.
    app.signIn(DemoIds.mika);
    await settle(tester);
    go(tester, '/event/$live/scan');
    await settle(tester);
    Future<void> scanRow(String name) async {
      final row = find.ancestor(
          of: find.text(name), matching: find.byType(ListTile));
      final btn = find.descendant(of: row.first, matching: find.text('Scan'));
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await settle(tester);
    }

    await scanRow('Ana Reyes');
    expect(find.text('Checked in'), findsOneWidget);
    await scanRow('Ana Reyes');
    expect(find.text('Already checked in'), findsOneWidget);
    expect(app.service.attendanceForEvent(live).length, 1);
    await scanRow('Sofia Santos');

    // 5 · The event ends (same transition as the demo control).
    app.service.endEventNow(live);
    await settle(tester);

    // 6 · Ana publishes a tagged post from attendance history.
    app.signIn(DemoIds.ana);
    await settle(tester);
    go(tester, '/history');
    await settle(tester);
    await tapText(tester, 'Share experience');
    expect(find.text('Pop and Pickle: Pickle Open Play'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'Won my first doubles game!');
    await settle(tester);
    await tapText(tester, '@mikacruz');
    await tapText(tester, '@sofiasantos');
    await tapText(tester, 'Publish post');
    final post = app.repo.posts.firstWhere((p) => p.eventId == live);
    expect(post.taggedIds, containsAll([DemoIds.mika, DemoIds.sofia]));
    expect(find.text('Won my first doubles game!'), findsOneWidget);
    expect(find.text('Repost'), findsNothing); // no repost control
  });

  final rsvpFooter = find.descendant(
    of: find.descendant(
      of: find.byType(RsvpsView),
      matching: find.byType(SliverFillRemaining),
    ),
    matching: find.byType(ColoredBox),
  );

  testWidgets('My RSVPs keeps the dark sheet to the bottom of a tall viewport',
      (tester) async {
    await boot(tester);
    tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
    app.signIn(DemoIds.ana);
    await settle(tester);
    go(tester, '/rsvps');
    await settle(tester);

    void expectDarkFooter() {
      final footer = tester.getRect(rsvpFooter);
      expect(footer.top,
          closeTo(tester.getRect(find.byType(DarkSheet)).bottom, 0.01));
      expect(footer.bottom, closeTo(1200, 0.01));
      expect(tester.widget<ColoredBox>(rsvpFooter).color,
          CarpsColors.light.inverse);
    }

    expectDarkFooter();
    // Filtering down to zero results should not expose the page background.
    await tester.tap(find.text('Wed'));
    await settle(tester);
    expect(find.text('No RSVPs on this day'), findsOneWidget);
    expectDarkFooter();
    await tapText(tester, 'Show all');
    expect(find.text('No RSVPs on this day'), findsNothing);
    expectDarkFooter();
  });

  testWidgets('My RSVPs scrolls on a narrow phone without a white footer',
      (tester) async {
    await boot(tester);
    tester.view.physicalSize = const Size(320 * 3, 540 * 3);
    const eventId = DemoIds.pickleballLive;
    app.service.requestToJoin(DemoIds.ana, eventId);
    final reg = app.service.registrationFor(eventId, DemoIds.ana)!;
    app.service.decide(DemoIds.mika, reg.id, approve: true);
    app.signIn(DemoIds.ana);
    await settle(tester);
    go(tester, '/rsvps');
    await settle(tester);

    final scrollable = find.descendant(
        of: find.byType(RsvpsView), matching: find.byType(Scrollable));
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));
    await tester.drag(scrollable, const Offset(0, -600));
    await settle(tester);
    expect(position.pixels, closeTo(position.maxScrollExtent, 0.01));
    final sheet = find.byType(DarkSheet);
    expect(tester.getRect(sheet).bottom, closeTo(540, 0.01));

    // Reproduce the offset during a bounce, regardless of test platform.
    position.jumpTo(position.maxScrollExtent + 48);
    await tester.pump();
    expect(position.pixels, greaterThan(position.maxScrollExtent));
    final footer = tester.getRect(rsvpFooter);
    expect(footer.top, closeTo(tester.getRect(sheet).bottom, 0.01));
    expect(footer.bottom, closeTo(540, 0.01));
    await settle(tester);

    await tapText(tester, 'Show my pass');
    final token = app.service.passFor(eventId, DemoIds.ana)!.token;
    expect(find.text(token), findsOneWidget);
  });

  testWidgets('declined user gets no pass', (tester) async {
    await boot(tester);
    app.signIn(DemoIds.mika);
    await settle(tester);
    go(tester, '/event/${DemoIds.pickleballLive}/roster');
    await settle(tester);
    final decline = find.text('Decline').first; // Marco is the only request
    await tester.ensureVisible(decline);
    await tester.tap(decline);
    await settle(tester);
    app.signIn(DemoIds.marco);
    await settle(tester);
    go(tester, '/pass/${DemoIds.pickleballLive}');
    await settle(tester);
    expect(find.text('No pass'), findsOneWidget);
    expect(find.textContaining('declined'), findsWidgets);
  });

  testWidgets('no-show cannot post: empty event picker', (tester) async {
    await boot(tester);
    app.signIn(DemoIds.paolo);
    await settle(tester);
    go(tester, '/compose');
    await settle(tester);
    expect(find.text('No attended events yet'), findsOneWidget);
    final publish = tester.widget<TextButton>(find.ancestor(
        of: find.text('Publish post'), matching: find.byType(TextButton)));
    expect(publish.onPressed, isNull);
  });

  testWidgets('failed lookup is distinct from empty and blocks publishing',
      (tester) async {
    await boot(tester);
    app.signIn(DemoIds.ana);
    app.setSimulateFailure(true);
    await settle(tester);
    go(tester, '/compose');
    await settle(tester);
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('No attended events yet'), findsNothing);
  });

  testWidgets('outsider cannot see the private tagged post anywhere',
      (tester) async {
    await boot(tester);
    final privateBody = app.repo.post(DemoIds.privatePost)!.body;
    app.signIn(DemoIds.bea);
    await settle(tester);
    for (final user in [DemoIds.ana, DemoIds.mika, DemoIds.sofia]) {
      go(tester, '/user/$user');
      await settle(tester);
      for (final tab in ['Posts', 'Tagged']) {
        await tapText(tester, tab);
        expect(find.text(privateBody), findsNothing, reason: '$user $tab');
        expect(find.text('Private Doubles Clinic'), findsNothing);
      }
    }
    go(tester, '/post/${DemoIds.privatePost}');
    await settle(tester);
    expect(find.text('Post unavailable'), findsOneWidget);
    go(tester, '/event/${DemoIds.clinicPast}');
    await settle(tester);
    expect(find.text('This event is private'), findsOneWidget);
    go(tester, '/feed');
    await settle(tester);
    expect(find.text(privateBody), findsNothing);

    // Ana attended, so she can read it.
    app.signIn(DemoIds.ana);
    await settle(tester);
    go(tester, '/post/${DemoIds.privatePost}');
    await settle(tester);
    expect(find.text(privateBody), findsOneWidget);
  });

  testWidgets('desktop width uses a navigation rail with Create event',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    app = AppController(MockCarpsRepository.seeded(now), clock: () => now)
      ..signIn(DemoIds.ana);
    await tester.pumpWidget(CarpsApp(controller: app));
    await settle(tester);
    expect(find.text('Create event'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo panel uses the real rules (switch user, scan, end)',
      (tester) async {
    await boot(tester);
    await tapText(tester, 'DEMO');
    expect(find.text('Demo controls'), findsOneWidget);
    await tapText(tester, 'Mika Cruz');
    expect(app.currentUserId, DemoIds.mika);

    await tapText(tester, 'DEMO');
    // Sofia holds an approved pass for the live session.
    await tapText(tester, 'Sofia Santos · this event');
    expect(find.textContaining('Checked in: Sofia Santos'), findsOneWidget);
    await tapText(tester, 'Sofia Santos · this event');
    expect(find.textContaining('Already checked in'), findsOneWidget);
    expect(app.service.attendanceForEvent(DemoIds.pickleballLive).length, 1);
    // A pass for another event is rejected as wrong-event.
    await tapText(tester, 'Unknown code');
    expect(find.textContaining('Invalid pass'), findsOneWidget);

    final live = app.repo.event(DemoIds.pickleballLive)!;
    expect(live.isEnded(now), isFalse);
    final endButtons = find.text('End now');
    await tester.ensureVisible(endButtons.first);
    await tester.tap(endButtons.first);
    await settle(tester);
    expect(app.repo.events.where((e) => e.isEnded(now)).length,
        greaterThan(4));
    // Ending doesn't grant eligibility to people who weren't scanned.
    expect(app.service.eligiblePostEvents(DemoIds.paolo), isEmpty);
  });

  test('seed sanity', () {
    final repo = MockCarpsRepository.seeded(now);
    expect(repo.events.where((e) => e.visibility == EventVisibility.private),
        isNotEmpty);
    expect(repo.events.where((e) => e.visibility == EventVisibility.public),
        isNotEmpty);
  });
}
