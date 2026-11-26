// Phone-width screenshots for comparing against the Figma frames.
//
// Skipped by default. To regenerate:
//   flutter test test/screenshots_test.dart --dart-define=CARPS_SHOTS=<absolute dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:carps/controllers/app_controller.dart';
import 'package:carps/main.dart';
import 'package:carps/repositories/mock_carps_repository.dart';
import 'package:carps/views/profile/rsvps_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _out = String.fromEnvironment('CARPS_SHOTS');

void main() {
  final now = DateTime(2026, 11, 24, 15);
  final key = GlobalKey();

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await t.pumpAndSettle();
  }

  Future<void> shot(WidgetTester t, String name) async {
    await settle(t);
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        final img = e.widget as Image;
        await precacheImage(img.image, e);
      }
    });
    await settle(t);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('phone screenshots', (t) async {
    t.view.physicalSize = const Size(390, 1500);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final app =
        AppController(MockCarpsRepository.seeded(now), clock: () => now);
    await t.pumpWidget(
        RepaintBoundary(key: key, child: CarpsApp(controller: app)));
    void go(String path) {
      final el = t.element(find.byType(Scaffold).first);
      ScaffoldMessenger.of(el).clearSnackBars();
      GoRouter.of(el).go(path);
    }

    Future<void> as(String user, String path, String name) async {
      app.signIn(user);
      await settle(t);
      go(path);
      await shot(t, name);
    }

    await shot(t, '01_login');
    go('/recover');
    await shot(t, '02_recovery');

    // Onboarding for a brand-new account.
    final fresh = app.service.signUp('newbie@example.com', 'longpassword');
    app.signIn(fresh.id);
    await shot(t, '03_terms');
    app.service.updateUser(app.me!.copyWith(termsAccepted: true));
    app.signIn(fresh.id);
    go('/home');
    await settle(t);

    await as(DemoIds.ana, '/home', '06_home');
    await as(DemoIds.ana, '/search', '07_search');
    await as(DemoIds.ana, '/event/${DemoIds.pickleballLive}', '08_event_guest');
    app.service.requestToJoin(DemoIds.ana, DemoIds.pickleballLive);
    await as(DemoIds.ana, '/event/${DemoIds.pickleballLive}', '08_event_pending');
    await as(DemoIds.bea, '/event/${DemoIds.clinicPast}', '08_event_denied');
    await as(DemoIds.mika, '/event/${DemoIds.pickleballLive}', '08_event_host');
    await as(DemoIds.mika, '/profile', '09_profile_builder');
    await as(DemoIds.bea, '/user/${DemoIds.ana}', '09_profile_visitor');
    await as(DemoIds.ana, '/edit-profile', '10_edit_profile');
    await as(DemoIds.ana, '/builder-setup', '11_builder_setup');
    await as(DemoIds.ana, '/followed', '12_followed');
    await as(DemoIds.mika, '/create', '13_create_event');
    await as(DemoIds.mika, '/event/${DemoIds.pickleballLive}/invites', '14_invites');
    await as(DemoIds.mika, '/event/${DemoIds.pickleballLive}/roster', '15_roster');
    await as(DemoIds.mika, '/event/${DemoIds.pickleballLive}/scan', '15_scanner');
    await as(DemoIds.mika, '/event/${DemoIds.pickleballPast}/analytics', '16_analytics');
    final reg = app.service.registrationFor(DemoIds.pickleballLive, DemoIds.ana)!;
    app.service.decide(DemoIds.mika, reg.id, approve: true);
    await as(DemoIds.ana, '/rsvps', '17_rsvps');
    t.view.physicalSize = const Size(346, 600);
    await settle(t);
    await t.drag(
      find.descendant(
        of: find.byType(RsvpsView),
        matching: find.byType(Scrollable),
      ),
      const Offset(0, -500),
    );
    await shot(t, '17_rsvps_scrolled');
    t.view.physicalSize = const Size(390, 1500);
    await as(DemoIds.ana, '/history', '18_history');
    await as(DemoIds.ana, '/compose?event=${DemoIds.pickleballPast}', '19_compose');
    await as(DemoIds.paolo, '/compose', '19_compose_noshow');
    await as(DemoIds.ana, '/post/${DemoIds.publicPost}', '20_post_detail');
    await as(DemoIds.ana, '/event/${DemoIds.clinicPast}/reviews', '21_reviews');
    await as(DemoIds.ana, '/settings', '22_settings');
    await as(DemoIds.ana, '/feed', '23_feed');
    await as(DemoIds.ana, '/notifications', '24_notifications');
    await as(DemoIds.ana, '/pass/${DemoIds.pickleballLive}', '25_pass');
    await as(DemoIds.sam, '/admin', '26_admin');
  }, skip: _out.isEmpty);
}
